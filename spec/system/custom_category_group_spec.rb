RSpec.describe "Testing Category Groups Theme Component", system: true do
  let!(:theme_component) { upload_theme_component }
  let!(:staff_category) { Fabricate(:category, name: "staff") }
  let!(:site_feedback_category) { Fabricate(:category, name: "site-feedback") }
  let!(:lounge_category) { Fabricate(:category, name: "lounge") }

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
          "url" => "/c/lounge",
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
      "Default Categories: staff, #{ExampleGroupLink.id}, site-feedback, lounge",
    )
    SiteSetting.desktop_category_page_style = "categories_boxes"
    theme_component.save!
  end

  it "should display the extra links" do
    visit "/categories"

    expect(page).to have_text ExampleGroupLink.title
    expect(page).to have_text ExampleGroupLink.description
    find(".extra-link-#{ExampleGroupLink.id}").click
    expect(page).to have_text "lounge topics"
  end
end
