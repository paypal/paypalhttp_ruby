configatron.product_name = "test product"

# Custom validations
def get_package_version
  File.open("braintreehttp.gemspec", 'r') do |f|
		f.each_line do |line|
      if line.match (/s\.version = "\d+.\d+.\d+"$/)
        return line.strip.split('"')[1]
			end
		end
	end
end

def validate_version_match
  package_version = get_package_version
	if package_version != @current_release.version
		Printer.fail("package version #{package_version} does not match changelog version #{@current_release.version}.")
		abort()
	end

	Printer.success("package version #{package_version} matches latest changelog version #{@current_release.version}.")
end

def test
  CommandProcessor.command("bundle exec rspec", live_output=true)
end

def validate_present(tool, install_command)
  tool_path = `which #{tool}`
  if tool_path.rstrip == ""
    Printer.fail("#{tool} not installed - please run `#{install_command}`")
    abort()
  else
    Printer.success("#{tool} found at #{tool_path}")
  end
end

def validate_bundle
  validate_present("bundle", "gem install bundler")
end

configatron.custom_validation_methods = [
  method(:validate_version_match),
  method(:validate_bundle),
  method(:test)
]

# Update version, build, and publish to rubygems
def update_version_method(version, semver_type)
  semver_regex = /  s\.version = "d+.d+.d+"$/
  contents = File.read("braintreehttp.gemspec")
  contents = contents.gsub(semver_regex, "  version = \"#{version}\"")
  File.open("braintreehttp.gemspec", "w") do |f|
    f << contents
  end
end

configatron.update_version_method = method(:update_version_method)

def clean
  CommandProcessor.command("rm -f braintreehttp-*.gem")
end

def build_method
  clean
  CommandProcessor.command("gem build braintreehttp.gemspec", live_output=true)
end

configatron.build_method = method(:build_method)

def publish_to_package_manager(version)
  CommandProcessor.command("gem push braintreehttp-#{version}.gem", live_outout=true)
end

configatron.publish_to_package_manager_method = method(:publish_to_package_manager)

def wait_for_package_manager(version)
  CommandProcessor.wait_for("wget -qO- https://rubygems.org/gems/braintreehttp/versions/#{version} | cat")
end

configatron.wait_for_package_manager_method = method(:wait_for_package_manager)

# Miscellania
configatron.prerelease_checklist_items = []
configatron.release_to_github = true
