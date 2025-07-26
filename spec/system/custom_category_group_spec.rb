# frozen_string_literal: true

RSpec.describe "Category Groups", system: true do
  let!(:theme_component) { upload_theme_component }
  let!(:category) { Fabricate(:category) }

  let(:id) { "some_id" }
  let(:title) { "Example" }
  let(:description) do
    "This is an example group. *The link description* supports **Markdown** formatting. :slightly_smiling_face:"
  end

  before do
    sign_in(Fabricate(:admin))
    theme_component.update_setting(
      :extra_links,
      [
        {
          "id" => id,
          "url" => "/c/#{category.slug}",
          "color" => "#ff0000",
          "title" => title,
          "description" => description,
          "icon" => "heart",
        },
      ].to_json,
    )
    theme_component.update_setting(:fancy_styling, true)
    theme_component.update_setting(:category_groups, "Default Categories: #{id}, #{category.slug}")
    SiteSetting.desktop_category_page_style = "categories_boxes"
    theme_component.save!
  end

  it "displays the extra links" do
    visit "/categories"

    extra_link = find(".extra-link-#{id}")
    expect(extra_link).to have_text title
    expect(extra_link[:innerHTML]).to include PrettyText.cook(description)
    extra_link.find("a").click
    expect(page).to have_text "#{category.name} topics"
  end

  it "renders markdown as html" do
    visit "/categories"

    expect(page).to have_tag("em", text: "The link description", count: 1)

    expect(page).to have_tag("strong", text: "Markdown", count: 1)

    expect(page).to have_tag(
      "img",
      with: {
        title: ":slightly_smiling_face:",
        alt: ":slightly_smiling_face:",
        class: "emoji",
      },
      count: 1,
    )
  end

  it "renders category badges" do
    visit "/categories"

    expect(page).to have_css(".category-box-heading .d-icon-heart", count: 1)
    expect(page).to have_css(".category-box-heading .--style-square", count: 2)
  end

  it "works with core category icons and emojis" do
    category.update!(style_type: "emoji", emoji: "wave")
    visit "/categories"

    expect(page).to have_css(".category-box-heading .emoji[alt='wave']", count: 1)
  end
end
