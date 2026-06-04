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
        let pendingLinks = [];

        tokens.forEach((token) => {
          const categoryId = helpers?.getCategoryIdBySlug?.(token);

          if (categoryId) {
            categories.push(categoryId);
            // Any links seen since the previous category were interleaved
            // before this one; preserve that position via `show_before`.
            pendingLinks.forEach((link) => (link.show_before = [categoryId]));
            pendingLinks = [];
          } else if (linksById.has(token)) {
            pendingLinks.push(linksById.get(token));
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
