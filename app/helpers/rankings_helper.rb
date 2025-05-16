module RankingsHelper
  def accuracy_color(accuracy)
    case accuracy
    when 80..100 then 'success'
    when 60...80 then 'info'
    when 40...60 then 'warning'
    else 'danger'
    end
  end
end