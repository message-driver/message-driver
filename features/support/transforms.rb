STRING_OR_SYM = Transform(/^:?[A-Za-z]\w*$/) do |str|
  case str
  when /^:/
    str.slice(1, str.length - 1).to_sym
  else
    str
  end
end

NUMBER = Transform(/^(?:\d+|a|an|no)$/) do |num|
  case num
  when 'no'
    0
  when 'a', 'an'
    1
  else
    Integer(num)
  end
end
