describe Multipart do
  describe 'mime_type_for_filename' do
    it 'supports gif' do
      expect(Multipart.new()._mime_type_for_file_name("test.gif")).to eq('image/gif')
    end

    it 'supports jpeg' do
      expect(Multipart.new()._mime_type_for_file_name("test.jpeg")).to eq('image/jpeg')
    end

    it 'supports jpg' do
      expect(Multipart.new()._mime_type_for_file_name("test.jpg")).to eq('image/jpeg')
    end

    it 'supports pdf' do
      expect(Multipart.new()._mime_type_for_file_name("test.pdf")).to eq('application/pdf')
    end

    it 'supports appication/octet-stream' do
      expect(Multipart.new()._mime_type_for_file_name("test.random")).to eq('application/octet-stream')
    end
  end
end
