module ServicesHelper
  def service_threshold_tag obj, name
    name = name.to_s
    pn = obj.send(name.to_sym)
    options = obj.type.metrics
    if pn.valid?
      content_tag :div, raw(concat_operator name, pn.array, pn, options), :class => 'threshold'
    end
  end

  private

  def concat_operator name, ar, pn, op
    ar = ar.dup
    pn_class = pn.class
    key = ar.shift
    str = ""
    left = hidden_field_tag "service[#{name}][]", "("
    right = hidden_field_tag "service[#{name}][]", ")"
    if pn_class.operator.include? key
      operate = select_tag "service[#{name}][]", options_for_select(Service.threshold_operate, key) 
      first = ar.shift
      str << %Q{
        <table>
          <tbody>
            <tr>
              <td colspan="2">
        #{left}
              </td>
            </tr>
      }
      str << %Q{
             <tr>
              <td rowspan="#{ar.size + 1}">
        #{operate}
              </td>
              <td>
        #{concat_operator(name, first, pn, op)}
              </td>
             </tr>
      }
      ar.each do |k|
        str << %Q{
             <tr>
              <td>
          #{concat_operator(name, k, pn, op)}
              </td>
             </tr>
        }
      end
      str << %Q{
            <tr>
              <td colspan="2">
        #{right}
              </td>
            </tr>
          </tbody>
        </table>
      }
    elsif pn_class.compare_operator.include? key
      operate = select_tag "service[#{name}][]", options_for_select(Service.threshold_condition, key), :class => "operator"
      text = select_tag "service[#{name}][]", options_from_collection_for_select(op, 'name', 'desc', ar[0]), :class => "key"
      val = text_field_tag("service[#{name}][]", ar[1], :class => "val")
      val = content_tag :span, val, :class => "text-wrap"
      str << content_tag(:div, left + content_tag(:span, operate + text) + val + right, :class => "cond clearfix")
    else
      str
    end
  end

end

