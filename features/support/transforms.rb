NUMBER = Transform(/^\d+|no$/) do |num|
  case num
  when 'no'
    0
  else
    num.to_i
  end
end

STRING_OR_SYM = Transform(/^:?\w+$/) do |str|
  case str
  when /^:/
    str.slice(1, str.length-1).to_sym
  else
    str
  end
end
