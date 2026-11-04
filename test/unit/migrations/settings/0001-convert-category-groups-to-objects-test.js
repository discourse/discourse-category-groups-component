import { module, test } from "qunit";
import migrate from "../../../../migrations/settings/0001-convert-category-groups-to-objects";

const helpers = {
  getCategoryIdBySlug(slug) {
    return { staff: 3, lounge: 4, feedback: 5 }[slug] || null;
  },
};

function link(attrs = {}) {
  return {
    id: "docs",
    url: "https://example.com/docs",
    title: "Docs",
    color: "#ff0000",
    ...attrs,
  };
}

module(
  "Unit | Migrations | Settings | 0001-convert-category-groups-to-objects",
  function () {
    test("converts groups and links to objects", function (assert) {
      const settings = new Map(
        Object.entries({
          category_groups: "Main: staff, docs, lounge|Extra: feedback, faq",
          extra_links: JSON.stringify([link(), link({ id: "faq" })]),
        })
      );

      const result = migrate(settings, helpers);

      assert.deepEqual(result.get("category_groups"), [
        { name: "Main", categories: [3, 4] },
        { name: "Extra", categories: [5] },
      ]);
      assert.deepEqual(result.get("extra_links"), [
        link({ show_before: [4] }),
        link({ id: "faq", show_in_group: "Extra" }),
      ]);
    });

    test("leaves settings that are already migrated", function (assert) {
      const settings = new Map(
        Object.entries({
          category_groups: [{ name: "Main", categories: [3] }],
          extra_links: [link()],
        })
      );

      const result = migrate(settings, helpers);

      assert.deepEqual(result.get("category_groups"), [
        { name: "Main", categories: [3] },
      ]);
      assert.deepEqual(result.get("extra_links"), [link()]);
    });

    test("skips groups with a blank name", function (assert) {
      const settings = new Map(
        Object.entries({ category_groups: "Main: staff|  : lounge" })
      );

      const result = migrate(settings, helpers);

      assert.deepEqual(result.get("category_groups"), [
        { name: "Main", categories: [3] },
      ]);
    });

    test("drops links with an empty url", function (assert) {
      const settings = new Map(
        Object.entries({
          category_groups: "Main: staff, empty, lounge",
          extra_links: JSON.stringify([link(), link({ id: "empty", url: "" })]),
        })
      );

      const result = migrate(settings, helpers);

      assert.deepEqual(result.get("category_groups"), [
        { name: "Main", categories: [3, 4] },
      ]);
      assert.deepEqual(result.get("extra_links"), [link()]);
    });

    test("drops links with a missing required field", function (assert) {
      const noColor = { id: "no-color", url: "/c/staff", title: "No color" };
      const settings = new Map(
        Object.entries({
          extra_links: JSON.stringify([link(), noColor]),
        })
      );

      const result = migrate(settings, helpers);

      assert.deepEqual(result.get("extra_links"), [link()]);
    });

    test("drops links with a whitespace-only required field", function (assert) {
      const settings = new Map(
        Object.entries({
          extra_links: JSON.stringify([link(), link({ title: "   " })]),
        })
      );

      const result = migrate(settings, helpers);

      assert.deepEqual(result.get("extra_links"), [link()]);
    });

    test("drops links with a non-string required field", function (assert) {
      const settings = new Map(
        Object.entries({
          extra_links: JSON.stringify([link(), link({ id: 13 })]),
        })
      );

      const result = migrate(settings, helpers);

      assert.deepEqual(result.get("extra_links"), [link()]);
    });
  }
);
