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
      "This is an example group"
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

    expect(page).to have_text ExampleGroupLink.title
    expect(page).to have_text ExampleGroupLink.description
    find(".extra-link-#{ExampleGroupLink.id}").click
    expect(page).to have_text "#{category.name} topics"
  end
end
