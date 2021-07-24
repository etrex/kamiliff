require 'test_helper'

class Kamiliff::Test < ActiveSupport::TestCase
  test "encode and decode" do
    params = {
      "path" => "/reservations/new?destination=a&flight_no=&number_of_bag=0&number_of_pax=1&pick_up_place=1",
      "size" => "TALL"
    }

    base64_string = Base64EncodeService.new(params).run
    decoded_params = Base64DecodeService.new(base64_string).run
    assert_equal params, decoded_params
  end
end
