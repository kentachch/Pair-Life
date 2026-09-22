module ApplicationHelper
  def category_icon(category, size: :sm)
    circle_class, icon_size = size == :lg ? [ "h-12 w-12", 24 ] : [ "h-10 w-10", 20 ]

    # data-icon にアイコン名を入れておくと、テストや開発者ツールでどのアイコンか確認しやすい
    tag.span(class: "flex #{circle_class} shrink-0 items-center justify-center rounded-full bg-blue-50 text-blue-600",
             data: { icon: category.icon }) do
      # lucide_icon は lucide-rails の Gem が用意しているヘルパー。SVG のアイコンを埋め込む
      lucide_icon(category.icon, size: icon_size, "aria-hidden": true)
    end
  end
end
