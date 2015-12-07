module CLIHelper
  def get_from_user(something, options)
    default_value = options[:default]
    STDOUT.write("Please enter a value for #{something}")
    STDOUT.write(" or, just hit Enter to stick with the default (#{default_value})") if default_value
    STDOUT.write(": ")
    user_entered_value = STDIN.gets.chomp
    user_entered_value.length == 0 ? default_value : user_entered_value
  end

  def get_required_from_user(something, options={})
    get_from_user(something, options) or abort("Sorry, #{something} is required.")
  end
end

