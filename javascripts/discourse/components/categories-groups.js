import Component from "@ember/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { categoryBadgeHTML } from "discourse/helpers/category-link";
import { slugify } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";

function parseSettings(settings) {
  return settings.split("|").map((i) => {
    const [categoryGroup, categories] = i.split(":").map((str) => str.trim());
    return { categoryGroup, categories };
  });
}

const ExtraLink = class {
  constructor(args) {
    this.isExtraLink = true;
    this.id = args.id;
    this.url = args.url;
    this.color = args.color;
    this.title = args.title;
    this.description = args.description;
    this.icon = args.icon;
  }
};

export default class CategoriesGroups extends Component {
  @service router;
  @service siteSettings;

  get shouldShow() {
    const currentRoute = this.router.currentRouteName;
    const categoryPageStyle = this.siteSettings.desktop_category_page_style;

    return (
      currentRoute === "discovery.categories" &&
      categoryPageStyle.includes("boxes")
    );
  }

  categoryName(category) {
    return htmlSafe(
      categoryBadgeHTML(category, {
        allowUncategorized: true,
        link: false,
      })
    );
  }

  get categoryGroupList() {
    const parsedSettings = parseSettings(settings.category_groups);
    const extraLinks = JSON.parse(settings.extra_links || "[]");

    // Initialize an array to keep track of found categories and used links
    const foundCategories = [];
    const usedLinks = [];

    // Helper function to find extra link by ID
    const findExtraLinkById = (id) => extraLinks.find((link) => link.id === id);

    // Iterate through parsed settings in the defined order
    const categoryGroupList = parsedSettings.reduce((groups, obj) => {
      const categoryArray = obj.categories.split(",").map((str) => str.trim());
      const categoryGroup = [];

      // Iterate through each category/link in the order specified in settings
      categoryArray.forEach((categoryOrLinkId) => {
        const category = this.categories.find(
          (cat) => cat.slug === categoryOrLinkId && !cat.hasMuted
        );

        if (category) {
          categoryGroup.push(category);
          foundCategories.push(category.slug);
        } else {
          const extraLink = findExtraLinkById(categoryOrLinkId);
          if (extraLink) {
            categoryGroup.push(new ExtraLink(extraLink));
            usedLinks.push(extraLink.id);
          }
        }
      });

      if (categoryGroup.length > 0) {
        groups.push({ name: obj.categoryGroup, items: categoryGroup });
      }
      return groups;
    }, []);

    // Find ungrouped categories
    const ungroupedCategories = this.categories.filter(
      (c) => !foundCategories.includes(c.slug) && c.notification_level !== 0
    );

    // Find muted categories
    const mutedCategories = settings.hide_muted_subcategories
      ? this.categories.filter((c) => c.notification_level === 0)
      : this.categories.filterBy("hasMuted");

    if (settings.show_ungrouped && ungroupedCategories.length > 0) {
      categoryGroupList.push({
        name: i18n(themePrefix("ungrouped_categories_title")),
        items: ungroupedCategories,
      });
    }

    if (mutedCategories.length > 0) {
      categoryGroupList.push({ name: "muted", items: mutedCategories });
    }

    return categoryGroupList;
  }

  @action
  toggleCategories(e) {
    const id = slugify(e);
    const storedCategories =
      JSON.parse(localStorage.getItem("categoryGroups")) || [];
    const categoryClass = `.custom-category-group-${id}`;

    if (storedCategories.includes(categoryClass)) {
      storedCategories.removeObject(categoryClass);
      document.querySelector(categoryClass)?.classList.add("is-expanded");
    } else {
      storedCategories.addObject(categoryClass);
      document.querySelector(categoryClass)?.classList.remove("is-expanded");
    }

    localStorage.setItem("categoryGroups", JSON.stringify(storedCategories));
  }

  @action
  initializeLocalStorage() {
    if (!localStorage.getItem("categoryGroups")) {
      localStorage.setItem(
        "categoryGroups",
        JSON.stringify([".custom-category-group-muted"])
      );
    }

    const storedCategories = JSON.parse(localStorage.getItem("categoryGroups"));
    storedCategories.forEach((category) => {
      document.querySelector(category)?.classList.remove("is-expanded");
    });
  }

  @action
  slugifyIdentifier(str) {
    return slugify(str);
  }
}
