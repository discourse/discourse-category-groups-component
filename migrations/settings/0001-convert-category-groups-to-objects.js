export default function migrate(settings, helpers) {
  const rawGroups = settings.get("category_groups");
  const rawLinks = settings.get("extra_links");

  // The original settings stored strings (list / json_schema). Once converted
  // they're arrays, so a non-string value means that setting is already migrated.
  const groupsNeedMigration = typeof rawGroups === "string";
  const linksNeedMigration = typeof rawLinks === "string";

  if (!groupsNeedMigration && !linksNeedMigration) {
    return settings;
  }

  const links = linksNeedMigration ? JSON.parse(rawLinks || "[]") : [];
  const linksById = new Map(links.map((link) => [link.id, link]));

  if (groupsNeedMigration) {
    const groups = rawGroups
      .split("|")
      .map((chunk) => {
        const [name, items] = chunk.split(":").map((str) => str.trim());

        if (!name) {
          return null;
        }

        const tokens = (items || "")
          .split(",")
          .map((str) => str.trim())
          .filter(Boolean);

        const categories = [];
        let lastCategoryId = null;

        tokens.forEach((token) => {
          const categoryId = helpers?.getCategoryIdBySlug?.(token);

          if (categoryId) {
            categories.push(categoryId);
            lastCategoryId = categoryId;
          } else if (linksById.has(token) && lastCategoryId) {
            // The token is an extra-link ID interleaved after a category;
            // preserve its position via the link's `show_after`.
            linksById.get(token).show_after = [lastCategoryId];
          }
        });

        return { name, categories };
      })
      .filter(Boolean);

    settings.set("category_groups", groups);
  }

  if (linksNeedMigration) {
    settings.set("extra_links", links);
  }

  return settings;
}
