RSpec::Matchers.define :orderlessly_match do |original_string|
  match do |given_string|
    original_string.split('').sort == given_string.split('').sort
  end

  failure_message_for_should do |given_string|
    "expected \"#{given_string}\" to have the same characters as \"#{original_string}\""
  end

  failure_message_for_should_not do |given_string|
    "expected \"#{given_string}\" not to have the same characters as \"#{original_string}\""
  end
end
