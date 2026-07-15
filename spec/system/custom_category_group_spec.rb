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
          "show_before" => [category.id],
        },
      ].to_json,
    )
    theme_component.update_setting(:fancy_styling, true)
    theme_component.update_setting(
      :category_groups,
      [
        {
          "name" => "Default Categories",
          "categories" => [category.id],
          "translations" => [{ "locale" => "fr", "name" => "Catégories par défaut" }],
        },
      ].to_json,
    )
    SiteSetting.desktop_category_page_style = "categories_boxes"
    theme_component.save!
  end

  it "displays the extra links" do
    visit "/categories"

    extra_link = find(".extra-link-#{id}")
    expect(extra_link).to have_text title
    expect(extra_link[:innerHTML]).to include PrettyText.cook(description)
    extra_link.find("a").click
    expect(page).to have_selector(
      "h1",
      text: I18n.t("js.discovery.headings.category.latest", category: category.name),
    )
  end

  it "renders markdown as html" do
    visit "/categories"

    expect(page).to have_css("em", exact_text: "The link description", count: 1)

    expect(page).to have_css("strong", exact_text: "Markdown", count: 1)

    expect(page).to have_css(
      'img.emoji[title=":slightly_smiling_face:"][alt=":slightly_smiling_face:"]',
      count: 1,
    )
  end

  it "renders category badges" do
    visit "/categories"

    within(".custom-category-group-default-categories") do
      expect(page).to have_css(".category-box-heading .d-icon-heart", count: 1)
      expect(page).to have_css(".category-box-heading .--style-square", count: 1)
    end
  end

  it "positions an extra link before its show_before category" do
    visit "/categories"

    expect(page).to have_css(
      ".custom-category-group-default-categories .extra-link-#{id} + .category-box-#{category.slug}",
    )
  end

  it "displays the group name in the default locale" do
    visit "/categories"

    expect(page).to have_css(
      ".custom-category-group-default-categories h2",
      text: "Default Categories",
    )
  end

  it "localizes the group name for the user's locale" do
    SiteSetting.allow_user_locale = true
    sign_in(Fabricate(:admin, locale: "fr"))

    visit "/categories"

    expect(page).to have_css(
      ".custom-category-group-default-categories h2",
      text: "Catégories par défaut",
    )
  end

  it "displays a group that contains only extra links" do
    theme_component.update_setting(
      :extra_links,
      [
        {
          "id" => "links-only-link",
          "url" => "https://meta.discourse.org",
          "color" => "#0000ff",
          "title" => "Community",
          "show_in_group" => "Just Links",
        },
      ].to_json,
    )
    theme_component.update_setting(
      :category_groups,
      [
        { "name" => "Default Categories", "categories" => [category.id] },
        { "name" => "Just Links", "categories" => [] },
      ].to_json,
    )
    theme_component.save!

    visit "/categories"

    within(".custom-category-group-just-links") do
      expect(page).to have_css(".extra-link-links-only-link", text: "Community")
    end
  end

  it "falls back to the ungrouped section when show_in_group matches no group" do
    theme_component.update_setting(
      :extra_links,
      [
        {
          "id" => "orphaned-link",
          "url" => "https://meta.discourse.org",
          "color" => "#00ff00",
          "title" => "Orphaned",
          "show_in_group" => "Renamed Group",
        },
      ].to_json,
    )
    theme_component.save!

    visit "/categories"

    within(".custom-category-group-ungrouped") do
      expect(page).to have_css(".extra-link-orphaned-link", text: "Orphaned")
    end
  end

  it "works with core category icons and emojis" do
    category.update!(style_type: "emoji", emoji: "wave")
    visit "/categories"

    expect(page).to have_css(".category-box-heading .emoji[alt='wave']", count: 1)
  end
end
