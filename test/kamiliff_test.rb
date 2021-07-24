require 'test_helper'

class Kamiliff::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Kamiliff
  end

  test "base64" do
    path = "/reservations/new?destination=a&flight_no=&number_of_bag=0&number_of_pax=1&pick_up_place=1"
    size = "TALL"
    base64_string = Base64EncodeService.new({
      path: path,
      liff_size: size
    }).run

    p base64_string
    p Base64DecodeService.new(base64_string).run
  end
end
