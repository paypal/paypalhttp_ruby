describe FormPart do
  describe 'initialize' do
    it 'Header-Cases lower-case headers' do
      lowerCaseFormPart = FormPart.new({:key => 'val'}, {'content-type': 'application/json'});

      expect(lowerCaseFormPart.headers.keys).to include('Content-Type')
      expect(lowerCaseFormPart.headers.keys.length).to eq(1)
    end

    it 'Header-Cases single char headers' do
      singleCharFormPart = FormPart.new({:key => 'val'}, {'x': 'application/json'});

      expect(singleCharFormPart.headers.keys).to include('X')
      expect(singleCharFormPart.headers.keys.length).to eq(1)
    end

    it 'Header-Cases keeps single header if collision' do
      multiHeaderFormPart = FormPart.new({:key => 'val'}, {'content-type': 'application/json', 'CONTENT-TYPE': 'application/pdf'});

      expect(multiHeaderFormPart.headers.keys).to include('Content-Type')
      expect(multiHeaderFormPart.headers.keys.length).to eq(1)
    end

    it 'Header-Cases multiple headers when supplied' do
      multiHeaderFormPart = FormPart.new({:key => 'val'}, {'header-one': 'application/json', 'header-Two': 'application/pdf', 'HEADER-THREE': 'img/jpg'});

      expect(multiHeaderFormPart.headers.keys).to include('Header-One')
      expect(multiHeaderFormPart.headers.keys).to include('Header-Two')
      expect(multiHeaderFormPart.headers.keys).to include('Header-Three')
      expect(multiHeaderFormPart.headers.keys.length).to eq(3)
    end
  end
end
