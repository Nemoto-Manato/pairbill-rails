# カテゴリの初期データ。
categories = [
  { category_name: "食費", display_order: 1 },
  { category_name: "日用品", display_order: 2 },
  { category_name: "家賃・光熱費", display_order: 3 },
  { category_name: "旅行・娯楽", display_order: 4 },
  { category_name: "その他", display_order: 5 }
]

categories.each do |attrs|
  Category.find_or_create_by!(category_name: attrs[:category_name]) do |category|
    category.display_order = attrs[:display_order]
    category.enabled = true
  end
end
