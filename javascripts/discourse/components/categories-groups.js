import { action } from "@ember/object";
import Component from "@ember/component";
import { dasherize } from "@ember/string";
import I18n from "I18n";
import { inject as service } from "@ember/service";

function parseSettings(settings) {
  return settings.split("|").map((i) => {
    const [categoryGroup, categories] = i.split(":").map((str) => str.trim());
    return { categoryGroup, categories };
  });
}

export default class CategoriesGroups extends Component {
  @service router;

  get shouldShow() {
    // we don't want this to show for subcategories within category routes
    return this.router.currentRouteName === "discovery.categories";
  }

  get categoryGroupList() {
    const buildCategoryGroup = (obj, foundCategories) => {
      return this.categories.filter((category) => {
        const categoryArray = obj.categories
          .split(",")
          .map((str) => str.trim());
        if (categoryArray.includes(category.slug) && !category.hasMuted) {
          foundCategories.push(category.slug);
          return true;
        }
        return false;
      });
    };

    const parsedSettings = parseSettings(settings.category_groups);
    const foundCategories = [];
    const categoryGroupList = parsedSettings.reduce((groups, obj) => {
      const categoryGroup = buildCategoryGroup(obj, foundCategories);
      if (categoryGroup.length > 0) {
        groups.push({ name: obj.categoryGroup, categories: categoryGroup });
      }
      return groups;
    }, []);
    const ungroupedCategories = this.categories.filter(
      (c) => !foundCategories.includes(c.slug)
    );
    const mutedCategories = this.categories.filterBy("hasMuted");

    if (settings.show_ungrouped && ungroupedCategories.length > 0) {
      categoryGroupList.push({
        name: I18n.t(themePrefix("ungrouped_categories_title")),
        categories: ungroupedCategories,
      });
    }

    if (mutedCategories.length > 0) {
      categoryGroupList.push({ name: "muted", categories: mutedCategories });
    }

    return categoryGroupList;
  }

  @action
  toggleCategories(e) {
    const id = dasherize(e);
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
}
