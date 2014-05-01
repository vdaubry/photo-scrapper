require 'spec_helper'
require 'mechanize'
require_relative '../../models/image_downloader'
require_relative '../../models/facades/ftp'

describe ImageDownloader do

	describe "build info" do
		before(:each) do
			@fake_date = DateTime.parse("01/01/2014")
			DateTime.stubs(:now).returns @fake_date
		end

		it "create a new image with parameters" do
			url = "http://foo.bar"
			
			img = ImageDownloader.new.build_info(123, 456, url)

			img.website_id.should == 123
			img.post_id.should == 456
			img.source_url.should == url
			img.key.should == @fake_date.to_i.to_s + "_" + File.basename(URI.parse(url).path)
			img.status.should == ImageDownloader::TO_SORT_STATUS
		end

		it "format special characters" do
			img = ImageDownloader.new.build_info(123, 456, "http://foo.bar/abc-jhvg-emil123.jpg")

			img.key.should == @fake_date.to_i.to_s + "_" + "abc_jhvg_emil123.jpg"
		end

		it "sets nil key if invalid uri" do
			img = ImageDownloader.new.build_info(123, 456, "http://foo.*malware*/img.jpg")
			img.key.should == nil
		end
	end

	describe "download" do
		let(:image) { ImageDownloader.new("calinours.jpg") }

		before(:each) do
			image.stub_chain(:open, :read) { File.open("spec/ressources/calinours.jpg").read }
			image.stubs(:generate_thumb).returns(true)
			image.stubs(:set_image_info).returns(true)
			image.stubs(:compress_image).returns(true)
		end

		it "uploads file to FTP" do
			Ftp.any_instance.expects(:upload_file).with(image)
			Image.stubs(:create).returns(Image.new({}))

			image.download.should == true
		end

		it "POST image to photo downloader" do
			params = {:source_url => "www.foo.bar/image.png", :hosting_url => "www.foo.bar", :key => "543_image.png", :status => "TO_SORT_STATUS", :image_hash => "dfg2345679876", :width => 400, :height => 400, :file_size => 123456, :website_id => 123, :post_id => 456}
			params.each {|k, v| image.instance_variable_set("@#{k}", v)}
			Image.stubs(:create).with(123, 456, "www.foo.bar/image.png", "www.foo.bar", "543_image.png", "TO_SORT_STATUS", "dfg2345679876", 400, 400, 123456).returns(Image.new({}))
			Ftp.any_instance.stubs(:upload_file).returns(nil)

			image.download.should == true
		end

		it "deletes image if API responds with nil" do
			Image.stubs(:create).returns(nil)
			Ftp.any_instance.expects(:upload_file).never

			image.download.should == false
		end		

		it "ignores file if API create image returns nil" do
			Image.stubs(:create).returns(nil)
			Ftp.any_instance.expects(:upload_file).never

			image.download.should == false
		end

		it "cleans temporary images" do
			Image.stubs(:create).returns(nil)
			ImageDownloader.stubs(:image_path).returns("spec/ressources/tmp/images")
			ImageDownloader.stubs(:thumbnail_path).returns("spec/ressources/tmp/images/thumbnails/300")
			FileUtils.cp("spec/ressources/calinours.jpg", image.image_save_path)
			FileUtils.cp("spec/ressources/calinours.jpg", image.thumbnail_save_path)
			
			image.download

			File.exist?(image.image_save_path).should == false
			File.exist?(image.thumbnail_save_path).should == false
		end

		context "raises exception" do
			before(:each) do
				image.stubs(:image_save_path).returns("spec/ressources/calinours.jpg")
				@image = ImageDownloader.new("calinours.jpg")
			end

			it "catches timeout error" do
				@image.stubs(:open).raises(Timeout::Error)
				@image.download.should == false
			end

			it "catches 404 error" do
				@image.stubs(:open).raises(OpenURI::HTTPError.new('',mock('io')))
				@image.download.should be_false
			end

			it "catches file not found" do
				@image.stubs(:open).raises(Errno::ENOENT)
				@image.download.should == false
			end

			it "catches connection error" do
				@image.stubs(:open).raises(Errno::ECONNRESET)
				@image.download.should == false
			end

			it "catches files error" do
				@image.stubs(:open).raises(EOFError)
				@image.download.should == false
			end

			it "catches socket error" do
				@image.stubs(:open).raises(SocketError)
				@image.download.should == false
			end

			it "catches mechanize responseCodeError" do
				page_image = mock()
				page_image.stubs(:url)
				page_image.stubs(:fetch).raises(Mechanize::ResponseCodeError.new(stub(:code=>404)))
				@image.download(page_image) == false
			end

			it "catches RuntimeEror" do
				@image.stubs(:open).raises(RuntimeError)
				@image.download.should == false
			end

			it "catches Zlib::BufError" do
				@image.stubs(:open).raises(Zlib::BufError)
				@image.download.should == false
			end

			it "catches Net::HTTP::Persistent::Error" do
				@image.stubs(:open).raises(Net::HTTP::Persistent::Error)
				@image.download.should == false
			end

			it "catches MiniMagick::Invalid" do
				@image.stubs(:open).raises(MiniMagick::Invalid)
				@image.download.should == false
			end

			it "catches memory error" do
				@image.stubs(:open).raises(Errno::ENOMEM)
				@image.download.should == false
			end
		end
	end

	describe "compress_image" do
		it "compresses image" do
			image = ImageDownloader.new(:key => "large_image.jpg")
			image.stubs(:image_save_path).returns("spec/ressources/large_image.jpg")
			image.compress_image
		end
	end


	describe "set_image_info" do
		let(:image) { ImageDownloader.new(:key => "calinours.jpg") }

		before(:each) do
			image.stubs(:image_save_path).returns("spec/ressources/calinours.jpg")
		end

		it  {
			image.set_image_info

			image.image_hash.should == "bf5ce4c682bd955f6ebd8b9ea03fe58a"
			image.file_size.should == 70994
			image.width.should == 600
			image.height.should == 390
		}
	end
end
