import { action } from "@ember/object";
import Component from "@ember/component";
import { dasherize } from "@ember/string";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import { schedule } from "@ember/runloop";

function parseSettings(settings) {
  let parsed = [];
  settings.split("|").map(i => {
      let seg = $.map(i.split(":"), $.trim);
      let catGroup = seg[0];
      let cats = seg[1];
      parsed.push({ catGroup: catGroup, cats: cats });
  });
  return parsed;
}

export default Component.extend({
  catGroupList: [],

  didInsertElement() {
    this._super(...arguments);

    schedule("afterRender", () => {

      if (localStorage.getItem("catGroups") === null) {
        let defaultObj = [".custom-category-group-muted"];
        localStorage.setItem("catGroups", JSON.stringify(defaultObj));
      }
    
      if (localStorage.getItem("catGroups")) {
        JSON.parse(localStorage.getItem("catGroups")).forEach(function(cat) {
          $(cat).removeClass("is-expanded");
        });
      }
 
    });
  },


  @discourseComputed("categories", "categories.length")
  catGroupList(categories, categoriesLength) {
    let catGroupList = [];
    let foundCats = [];

    const parsedSettings = parseSettings(settings.category_groups);

    parsedSettings.forEach(function(obj) {
      let orderedCats = new Map();
      // loop once over all existing categories, preserve order when adding found categories
      categories.forEach((c) => {
          let i = obj.cats.indexOf(c.slug);
          if (i > -1 && !c.hasMuted) {
              foundCats.push(c.slug);
              orderedCats.set(i, c);
          }
      })
      // Sort by key (index in settings string)
      let sorted = [...orderedCats.entries()].sort((a,b) => a[0] > b[0]);
      orderedCats = new Map (sorted);
      let catGroup = Array.from(orderedCats.values())
      if (catGroup.length) { // don't show empty groups
        catGroupList.push({ name: obj.catGroup, cats: catGroup });
      }
    });

    
    let ungroupedCats = categories.filter((c) => {
      return foundCats.indexOf(c.slug) == -1
    })
    let mutedCats = categories.filterBy("hasMuted");  
    
    if (settings.show_ungrouped) {
      if (ungroupedCats.length) {
        catGroupList.push({ name: I18n.t(themePrefix("ungrouped_categories_title"))
        , cats: ungroupedCats });
      }
    }

    if (mutedCats.length) {
      catGroupList.push({ name: "muted", cats: mutedCats });
    }

    return catGroupList;
  },

  @action
  toggleCats(e) {
    let id = dasherize(e);
    let storedCats = JSON.parse(localStorage.getItem("catGroups"));

    if (
      (storedCats != null) &&
      (storedCats.indexOf(".custom-category-group-" + id) > -1)
    ) {
      let index = storedCats.indexOf(".custom-category-group-" + id);
      if (index >= 0) {
        storedCats.splice( index, 1 );
      }
      $(".custom-category-group-" + id).addClass("is-expanded");
      localStorage.setItem("catGroups", JSON.stringify(storedCats));
    } else {
      storedCats.push(".custom-category-group-" + id);
      $(".custom-category-group-" + id).removeClass("is-expanded");
      localStorage.setItem("catGroups", JSON.stringify(storedCats));
    }
  }
  
});
