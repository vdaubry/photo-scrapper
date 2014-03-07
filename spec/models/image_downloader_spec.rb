require 'spec_helper'
require_relative '../../models/image_downloader'
require_relative '../../models/facades/ftp'

describe ImageDownloader do

	describe "build info" do
		it "create a new image with parameters" do
			fake_date = DateTime.parse("01/01/2014")
			DateTime.stubs(:now).returns fake_date
			url = "http://foo.bar"
			
			img = ImageDownloader.new.build_info(url)

			img.source_url.should == url
			img.key.should == fake_date.to_i.to_s + "_" + File.basename(URI.parse(url).path)
			img.status.should == ImageDownloader::TO_SORT_STATUS
		end

		it "format special characters" do
			fake_date = DateTime.parse("01/01/2014")
			DateTime.stubs(:now).returns fake_date
			url = "http://foo.bar/abc-jhvg-emil123.jpg"

			img = ImageDownloader.new.build_info(url)

			img.key.should == fake_date.to_i.to_s + "_" + "abc_jhvg_emil123.jpg"
		end
	end

	describe "download" do
		let(:image) { ImageDownloader.new("calinours.jpg") }

		it "POST image to photo downloader" do
			ImageDownloader.stubs(:image_path).returns("spec/ressources")
			ImageDownloader.stubs(:thumbnail_path).returns("spec/ressources/thumb")
			image.stub_chain(:open, :read) { File.open("ressources/calinours.jpg").read }

			image.download

			
		end

		context "raises exception" do
			before(:each) do
				image.stubs(:image_save_path).returns("spec/ressources/calinours.jpg")
				@image = ImageDownloader.new("calinours.jpg")
			end

			it "catches timeout error and keep image" do
				@image.stubs(:open).raises(Timeout::Error)
				@image.download
			end

			it "catches 404 error and delete image" do
				@image.stubs(:open).raises(OpenURI::HTTPError.new('',mock('io')))
				@image.download
			end

			it "catches file not found and keep image" do
				@image.stubs(:open).raises(Errno::ENOENT)
				@image.download
			end
		end

		it "uploads file to FTP" do
			image.stub_chain(:open, :read) { File.open("spec/ressources/calinours.jpg").read }
			image.stubs(:generate_thumb).returns(true)
			image.stubs(:set_image_info).returns(true)
			Ftp.any_instance.expects(:upload_file).with(image)

			image.download
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

	describe "image_invalid?" do
		let(:img) { ImageDownloader.new }
		it { img.width = 300
				 img.height = 300
				 img.image_invalid?.should == false }

		it { img.width = 200
				 img.height = 2000
				 img.image_invalid?.should == true 
				}

		it { img.width = 2000
				 img.height = 200
				 img.image_invalid?.should == true 
				}
	end
end
