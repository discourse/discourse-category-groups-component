/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import CategoryLogo from "discourse/components/category-logo";
import CategoryTitleBefore from "discourse/components/category-title-before";
import CategoryTitleLink from "discourse/components/category-title-link";
import CdnImg from "discourse/components/cdn-img";
import PluginOutlet from "discourse/components/plugin-outlet";
import borderColor from "discourse/helpers/border-color";
import categoryLink, {
  categoryBadgeHTML,
} from "discourse/helpers/category-link";
import icon from "discourse/helpers/d-icon";
import lazyHash from "discourse/helpers/lazy-hash";
import { slugify } from "discourse/lib/utilities";
import I18nInstance, { i18n } from "discourse-i18n";
import CategoryGroupExtraLink from "./category-group-extra-link";

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

  localizedGroupName(group) {
    const locale = I18nInstance.currentLocale();
    const translation = (group.translations || []).find(
      (t) => t.locale === locale
    );
    return translation?.name || group.name;
  }

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
    const parsedSettings = settings.category_groups;
    const extraLinks = settings.extra_links || [];

    // Keep track of which categories landed in a group so the rest fall through
    // to the "ungrouped" section.
    const foundCategories = [];

    // Returns each category preceded by any extra links positioned before it
    // (via the link's `show_before` category), so links render inline next to a
    // category.
    const withLinks = (categories) => {
      const items = [];
      categories.forEach((category) => {
        extraLinks
          .filter((link) => (link.show_before || []).includes(category.id))
          .forEach((link) => items.push(new ExtraLink(link)));
        items.push(category);
      });
      return items;
    };

    // Iterate through parsed settings in the defined order
    const categoryGroupList = parsedSettings.reduce((groups, obj) => {
      const groupCategories = (obj.categories || [])
        .map((id) =>
          this.categories.find((cat) => cat.id === Number(id) && !cat.hasMuted)
        )
        .filter(Boolean);

      groupCategories.forEach((c) => foundCategories.push(c.slug));

      const items = withLinks(groupCategories);

      if (items.length > 0) {
        // `slug` is derived from the default name so it stays stable across
        // locales (used for CSS classes and localStorage collapse state),
        // while `name` is the localized label shown to the user.
        groups.push({
          name: this.localizedGroupName(obj),
          slug: slugify(obj.name),
          items,
        });
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
      : this.categories.filter((c) => c.hasMuted);

    if (settings.show_ungrouped && ungroupedCategories.length > 0) {
      categoryGroupList.push({
        name: i18n(themePrefix("ungrouped_categories_title")),
        slug: "ungrouped",
        items: withLinks(ungroupedCategories),
      });
    }

    if (mutedCategories.length > 0) {
      categoryGroupList.push({
        name: i18n(themePrefix("muted_categories_title")),
        slug: "muted",
        items: mutedCategories,
      });
    }

    return categoryGroupList;
  }

  @action
  toggleCategories(slug, event) {
    event.preventDefault();

    const storedCategories =
      JSON.parse(localStorage.getItem("categoryGroups")) || [];
    const categoryClass = `.custom-category-group-${slug}`;

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

  <template>
    {{#if this.shouldShow}}
      <section class="category-boxes with-logos with-subcategories">
        <div
          class="custom-categories-groups"
          {{didInsert this.initializeLocalStorage}}
        >
          {{#each this.categoryGroupList as |t|}}
            <div class="custom-category-group-{{t.slug}} is-expanded">
              <a
                {{on "click" (fn this.toggleCategories t.slug)}}
                href
                id={{t.slug}}
                class="custom-category-group-toggle"
              >
                <h2>{{t.name}}</h2>
                {{icon "angle-right"}}
              </a>

              <ul class="custom-category-group">
                {{#each t.items as |c|}}
                  {{#if c.isExtraLink}}
                    <CategoryGroupExtraLink @link={{c}} />
                  {{else}}
                    <PluginOutlet
                      @name="category-box-before-each-box"
                      @outletArgs={{lazyHash category=c}}
                    />

                    {{! modified version of the core categories-boxes layout }}
                    <li
                      style={{unless
                        this.noCategoryStyle
                        (borderColor c.color)
                      }}
                      data-category-id={{c.id}}
                      data-notification-level={{c.notificationLevelString}}
                      data-url={{c.url}}
                      class="category category-box category-box-{{c.slug}}
                        {{if c.isMuted 'muted'}}
                        {{if this.noCategoryStyle 'no-category-boxes-style'}}"
                    >
                      <div class="category-box-inner">
                        <div class="category-logo">
                          {{#if c.uploaded_logo.url}}
                            <CategoryLogo @category={{c}} />
                          {{/if}}
                        </div>
                        <div class="category-details">
                          <div class="category-box-heading">
                            <a class="parent-box-link" href={{c.url}}>
                              <h3>{{this.categoryName c}}</h3>
                            </a>
                          </div>

                          <div class="description">
                            {{htmlSafe c.description_excerpt}}
                          </div>
                          {{#if c.isGrandParent}}
                            {{#each c.subcategories as |subcategory|}}
                              <div
                                data-category-id={{subcategory.id}}
                                data-notification-level={{subcategory.notificationLevelString}}
                                style={{borderColor subcategory.color}}
                                class="subcategory with-subcategories
                                  {{if
                                    subcategory.uploaded_logo.url
                                    'has-logo'
                                    'no-logo'
                                  }}"
                              >
                                <div class="subcategory-box-inner">
                                  <CategoryTitleLink
                                    @tagName="h4"
                                    @category={{subcategory}}
                                  />
                                  {{#if subcategory.subcategories}}
                                    <div class="subcategories">
                                      {{#each
                                        subcategory.subcategories
                                        as |subsubcategory|
                                      }}
                                        {{#unless subsubcategory.isMuted}}
                                          <span class="subcategory">
                                            <CategoryTitleBefore
                                              @category={{subsubcategory}}
                                            />
                                            {{categoryLink
                                              subsubcategory
                                              hideParent="true"
                                            }}
                                          </span>
                                        {{/unless}}
                                      {{/each}}
                                    </div>
                                  {{/if}}
                                </div>
                              </div>
                            {{/each}}
                          {{else if c.subcategories}}
                            <div class="subcategories">
                              {{#each c.subcategories as |sc|}}
                                <a class="subcategory" href={{sc.url}}>
                                  <span class="subcategory-image-placeholder">
                                    <CdnImg
                                      @src={{sc.uploaded_logo.url}}
                                      @class="logo"
                                      @width={{sc.uploaded_logo.width}}
                                      @height={{sc.uploaded_logo.height}}
                                      @alt=""
                                    />
                                  </span>
                                  {{categoryLink sc hideParent="true"}}
                                </a>
                              {{/each}}
                            </div>
                          {{/if}}
                        </div>
                        <PluginOutlet
                          @name="category-box-below-each-category"
                          @outletArgs={{lazyHash category=c}}
                        />
                      </div>
                    </li>
                  {{/if}}
                {{/each}}
              </ul>
            </div>
          {{/each}}
        </div>
      </section>
    {{/if}}
  </template>
}
