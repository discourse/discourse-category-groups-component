export default function migrate(settings) {
    if (settings.has("category_groups")) {
        const groups = settings.get("category_groups");
        const categoryGroups = groups.split("|").map((i) => {
            const [categoryGroup, categories] = i.split(":").map((str) => str.trim());
            return { categoryGroup, categories, visibility: [0] };
        });

        settings.set("grouped_categories", categoryGroups);
        settings.delete("category_groups");
    }

    if (settings.has("extra_links")) {
        const links = settings.get("extra_links");
        settings.set("links", JSON.parse(links || "[]"));
        settings.delete("extra_links");
    }

    return settings;
}