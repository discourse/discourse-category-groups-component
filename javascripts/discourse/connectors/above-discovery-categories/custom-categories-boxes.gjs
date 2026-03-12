/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { classNames } from "@ember-decorators/component";
import { and, or } from "discourse/truth-helpers";
import CategoriesGroups from "../../components/categories-groups";

@classNames("above-discovery-categories-outlet", "custom-categories-boxes")
export default class CustomCategoriesBoxes extends Component {
  <template>
    {{#if
      (or
        this.site.desktopView (and settings.show_on_mobile this.site.mobileView)
      )
    }}
      <CategoriesGroups @categories={{this.outletArgs.categories}} />
    {{/if}}
  </template>
}
