# frozen_string_literal: true
RSpec.describe "Testing Category Groups Theme Component", system: true do
  let!(:theme_component) { upload_theme_component }
  let!(:category) { Fabricate(:category) }

  class ExampleGroupLink
    def self.id
      "some_id"
    end
    def self.title
      "Example"
    end
    def self.description
      "This is an example group. *The link description* supports **Markdown** formatting. :slightly_smiling_face:"
    end
  end

  before do
    sign_in(Fabricate(:admin))
    theme_component.update_setting(
      :extra_links,
      [
        {
          "id" => ExampleGroupLink.id,
          "url" => "/c/#{category.slug}",
          "color" => "#ff0000",
          "title" => ExampleGroupLink.title,
          "description" => ExampleGroupLink.description,
          "icon" => "heart",
        },
      ].to_json,
    )
    theme_component.update_setting(:fancy_styling, true)
    theme_component.update_setting(
      :category_groups,
      "Default Categories: #{ExampleGroupLink.id}, #{category.slug}",
    )
    SiteSetting.desktop_category_page_style = "categories_boxes"
    theme_component.save!
  end

  it "should display the extra links" do
    visit "/categories"

    extra_link = find(".extra-link-#{ExampleGroupLink.id}")
    expect(extra_link).to have_text ExampleGroupLink.title
    expect(extra_link[:innerHTML]).to include PrettyText.cook(ExampleGroupLink.description)
    extra_link.find("a").click
    expect(page).to have_text "#{category.name} topics"
  end

  it "should render markdown as html" do
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
end
