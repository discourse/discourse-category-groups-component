import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { htmlSafe } from "@ember/template";
import borderColor from "discourse/helpers/border-color";
import { cook } from "discourse/lib/text";
import dIcon from "discourse-common/helpers/d-icon";
import I18n from "discourse-i18n";

export default class CategoryGroupExtraLink extends Component {
  @tracked cookedDescription = I18n.t("loading");

  constructor() {
    super(...arguments);
    this.cookDescription(this.args.link.description);
  }

  cookDescription(description) {
    return cook(description)
      .then(htmlSafe)
      .then((cooked) => (this.cookedDescription = cooked));
  }

  get borderColor() {
    // Using JSON schema we get the hash, and then borderColor adds another one. Slice it out!
    return this.args.link.color.slice(1);
  }
  <template>
    <li
      style={{borderColor this.borderColor}}
      class="extra-link category-box extra-link-{{@link.id}}"
    >
      <div class="category-box-inner">
        <div class="category-details">
          <div class="category-box-heading">
            <a class="parent-box-link" href={{@link.url}}>
              {{dIcon @link.icon}}
              <h3 class="title">
                {{@link.title}}
              </h3>
            </a>
          </div>

          <div class="description">
            {{this.cookedDescription}}
          </div>
        </div>
      </div>
    </li>
  </template>
}
