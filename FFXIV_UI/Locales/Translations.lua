local addonName, ns = ...

-- Keys are the English strings. Missing keys fall back to English.
ns.RegisterLocale("deDE", {
    ["Cast"] = "Zauberzeit", ["Recast"] = "Neuaufladung", ["Instant"] = "Spontan",
    ["Bonuses"] = "Boni", ["Effects"] = "Effekte", ["%s Cost"] = "%s-Kosten",
})
ns.RegisterLocale("frFR", {
    ["Cast"] = "Incantation", ["Recast"] = "Recharge", ["Instant"] = "Instantané",
    ["Bonuses"] = "Bonus", ["Effects"] = "Effets", ["%s Cost"] = "Coût en %s",
})
ns.RegisterLocale("esES", {
    ["Cast"] = "Lanzamiento", ["Recast"] = "Reutilización", ["Instant"] = "Instantáneo",
    ["Bonuses"] = "Bonificaciones", ["Effects"] = "Efectos", ["%s Cost"] = "Coste de %s",
})
ns.RegisterLocale("esMX", {
    ["Cast"] = "Lanzamiento", ["Recast"] = "Reutilización", ["Instant"] = "Instantáneo",
    ["Bonuses"] = "Bonificaciones", ["Effects"] = "Efectos", ["%s Cost"] = "Costo de %s",
})
ns.RegisterLocale("itIT", {
    ["Cast"] = "Lancio", ["Recast"] = "Ricarica", ["Instant"] = "Istantaneo",
    ["Bonuses"] = "Bonus", ["Effects"] = "Effetti", ["%s Cost"] = "Costo %s",
})
ns.RegisterLocale("ptBR", {
    ["Cast"] = "Conjuração", ["Recast"] = "Recarga", ["Instant"] = "Instantâneo",
    ["Bonuses"] = "Bônus", ["Effects"] = "Efeitos", ["%s Cost"] = "Custo de %s",
})
ns.RegisterLocale("ruRU", {
    ["Cast"] = "Применение", ["Recast"] = "Перезарядка", ["Instant"] = "Мгновенно",
    ["Bonuses"] = "Бонусы", ["Effects"] = "Эффекты", ["%s Cost"] = "Стоимость: %s",
})
ns.RegisterLocale("koKR", {
    ["Cast"] = "시전", ["Recast"] = "재사용", ["Instant"] = "즉시",
    ["Bonuses"] = "보너스", ["Effects"] = "효과", ["%s Cost"] = "%s 소모",
})
ns.RegisterLocale("zhCN", {
    ["Cast"] = "咏唱", ["Recast"] = "复唱", ["Instant"] = "瞬发",
    ["Bonuses"] = "加成", ["Effects"] = "效果", ["%s Cost"] = "%s消耗",
})
ns.RegisterLocale("zhTW", {
    ["Cast"] = "詠唱", ["Recast"] = "再詠唱", ["Instant"] = "瞬發",
    ["Bonuses"] = "加成", ["Effects"] = "效果", ["%s Cost"] = "%s消耗",
})
