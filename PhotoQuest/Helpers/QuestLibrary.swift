import Foundation

// MARK: - Словарь соответствий «русское слово → английские классы ImageNet»

/// Словарь для проверки фотографий: ключ — русское слово (или фраза),
/// значение — массив английских названий классов, которые MobileNetV2
/// (обучена на ImageNet) может вернуть в результате классификации.
///
/// Названия классов чувствительны к регистру только в файле модели:
/// в коде сравнение идёт в нижнем регистре по словам.
enum QuestKeywords {

    /// Базовые группы ключевых слов.
    static let all: [String: [String]] = [
        // Животные
        "кот": ["tabby", "tiger cat", "persian cat", "siamese cat", "egyptian cat", "lynx", "cat"],
        "собака": ["golden retriever", "labrador retriever", "beagle", "chihuahua", "poodle", "pug",
                   "rottweiler", "siberian husky", "whippet", "greyhound", "collie", "dalmatian",
                   "doberman", "boxer", "bulldog", "maltese", "shih-tzu", "pekingese", "newfoundland",
                   "great dane", "briard", "keeshond", "pomeranian", "cairn", "basset hound",
                   "bloodhound", "cocker spaniel", "english setter", "german shepherd", "borzoi",
                   "miniature schnauzer", "papillon", "toy terrier", "dog", "puppy"],
        "птица": ["robin", "magpie", "jay", "sparrow", "finch", "chickadee", "hummingbird", "cock",
                  "hen", "goose", "duck", "swan", "pelican", "stork", "flamingo", "ostrich",
                  "peacock", "owl", "eagle", "hawk", "parrot", "macaw", "bird", "kite", "vulture",
                  "quail", "goldfinch", "junco", "brambling", "meadowlark", "bulbul", "house finch",
                  "indigo bunting", "sea gull", "oystercatcher", "partridge", "pheasant",
                  "ptarmigan", "red-breasted merganser", "great grey owl", "water ouzel",
                  "sulphur-crested cockatoo"],
        "лошадь": ["horse", "pony", "sorrel"],
        "дикое животное": ["lion", "tiger", "leopard", "zebra", "elephant", "giraffe", "monkey",
                           "chimpanzee", "orangutan", "gibbon", "kangaroo", "koala", "panda",
                           "brown bear", "polar bear", "wolf", "red fox", "rabbit", "squirrel",
                           "hedgehog", "raccoon", "skunk", "porcupine", "jaguar", "cheetah", "cougar",
                           "hippopotamus", "rhinoceros", "camel", "llama", "bison", "antelope",
                           "gazelle", "impala", "elk", "moose", "boar", "warthog", "water buffalo",
                           "yak", "armadillo", "sloth", "otter", "bat", "hamster", "mouse", "rat",
                           "chinchilla", "gerbil"],
        "рыба": ["goldfish", "trout", "shark", "eel", "stingray", "barracouta", "coho", "tench",
                 "puffer", "gar", "sturgeon"],
        "бабочка": ["butterfly", "admiral", "monarch", "cabbage butterfly", "lycaenid", "ringlet",
                    "sulphur butterfly"],
        "насекомое": ["bee", "beetle", "ladybug", "ant", "dragonfly", "grasshopper", "cricket",
                      "spider", "snail", "caterpillar", "centipede", "earwig", "fly", "wasp",
                      "hornet", "cicada", "firefly", "mantis", "moth", "scorpion", "termite"],
        "морское": ["starfish", "jellyfish", "crab", "lobster", "octopus", "conch", "coral reef",
                    "sea lion", "sea anemone", "sea snake", "sea urchin", "crayfish", "isopod",
                    "barnacle", "limpet", "abalone"],

        // Дом
        "часы": ["wall clock", "digital clock", "analog clock", "stopwatch", "sundial",
                 "digital watch", "clock", "watch"],
        "круглое": ["soccer ball", "basketball", "baseball", "tennis ball", "volleyball", "golf ball",
                    "ping-pong ball", "cricket ball", "rugby ball", "ball", "plate", "wheel", "coin",
                    "donut", "orange", "balloon", "globe", "clock"],
        "книга": ["book jacket", "bookcase", "bookshelf", "library", "bookshop", "comic book",
                  "menu", "notebook", "magazine"],
        "кружка": ["coffee mug", "teacup", "cup", "espresso", "cappuccino"],
        "посуда": ["soup bowl", "plate", "spoon", "fork", "teapot", "frying pan", "wok",
                   "cocktail shaker", "measuring cup", "teakettle", "mixing bowl", "pot"],
        "обувь": ["running shoe", "clog", "sandal", "cowboy boot", "hiking boot", "high-heel",
                  "shoe shop", "shoe"],
        "одежда": ["sweater", "sweatshirt", "jersey", "kimono", "gown", "bathrobe", "poncho", "jean",
                   "trench coat", "cardigan", "fur coat", "sarong", "serape", "abaya", "miniskirt",
                   "vestment", "maillot", "tuxedo", "suit", "pajama", "nightie", "cloak", "bib",
                   "apron", "lab coat", "swimming trunks", "bathing cap"],
        "головной убор": ["sombrero", "cowboy hat", "baseball cap", "bonnet", "mortarboard", "beret",
                          "fedora", "sun hat", "crash helmet", "football helmet", "pith helmet",
                          "ski mask"],
        "очки": ["sunglasses", "eyeglasses", "goggles"],
        "сумка": ["backpack", "handbag", "shoulder bag", "purse", "wallet", "shopping basket",
                  "shopping cart", "suitcase"],
        "замок": ["padlock", "doorknob", "combination lock", "lock"],
        "окно": ["window screen", "window shade", "sliding door", "curtain"],
        "лампа": ["table lamp", "lampshade", "candle", "torch", "spotlight", "candle holder"],
        "игрушка": ["teddy", "balloon", "jigsaw puzzle", "pinwheel", "rubik's cube", "swing",
                    "crib", "cradle", "toyshop"],
        "подушка": ["pillow", "quilt", "comforter", "sleeping bag"],
        "ваза": ["vase", "flowerpot"],
        "зеркало": ["looking glass"],
        "мебель": ["four-poster bed", "couch", "crib", "cradle", "bench", "throne", "barber chair",
                   "rocking chair", "folding chair", "swing", "dining table", "china cabinet",
                   "wardrobe", "medicine chest", "bookcase", "pillow", "quilt", "comforter",
                   "sleeping bag"],
        "комнатное растение": ["flowerpot", "vase", "banyan", "fig", "weeping willow", "palm",
                               "christmas tree", "coral tree"],

        // Техника
        "телефон": ["cellular telephone", "pay-phone", "ipod"],
        "компьютер": ["laptop", "laptop computer", "notebook", "notebook computer", "desktop computer",
                      "hand-held computer", "monitor", "computer keyboard", "computer mouse",
                      "printer", "modem", "hard disc"],
        "телевизор": ["television", "remote control", "projector"],
        "пульт": ["remote control", "television"],
        "клавиатура": ["computer keyboard", "desktop computer"],
        "мышь": ["computer mouse", "desktop computer"],
        "принтер": ["printer", "desktop computer"],
        "плеер": ["cd player", "ipod", "cassette player"],

        // Транспорт
        "машина": ["sports car", "convertible", "jeep", "limousine", "taxi", "minivan", "beach wagon",
                   "racer", "cab", "car"],
        "велосипед": ["bicycle-built-for-two", "mountain bike", "tricycle", "unicycle", "bicycle"],
        "мотоцикл": ["motorcycle", "scooter", "moped", "motor scooter"],
        "самолёт": ["airliner", "warplane", "fighter", "airship", "balloon", "space shuttle", "missile"],
        "корабль": ["container ship", "fireboat", "lifeboat", "speedboat", "tugboat", "canoe",
                    "kayak", "pirate", "schooner", "yawl", "gondola", "wreck", "submarine",
                    "aircraft carrier"],
        "поезд": ["bullet train", "electric locomotive", "steam locomotive", "freight car",
                  "passenger car", "subway"],
        "вертолёт": ["helicopter"],
        "автобус": ["school bus", "trolleybus", "taxi", "cab", "minivan", "passenger car"],

        // Еда
        "фрукт": ["apple", "banana", "orange", "lemon", "pineapple", "peach", "pomegranate", "pear",
                  "mango", "fig", "red apple", "granny smith", "strawberry"],
        "цитрус": ["orange", "lemon", "citron"],
        "овощ": ["cauliflower", "broccoli", "cabbage", "cucumber", "artichoke", "bell pepper",
                 "hot pepper", "zucchini", "eggplant", "corn", "lettuce", "pumpkin", "carrot",
                 "radish", "sweet potato", "butternut squash", "spaghetti squash", "cardoon",
                 "celery", "rhubarb", "turnip", "yellow squash", "acorn squash"],
        "пицца": ["pizza"],
        "фастфуд": ["hamburger", "cheeseburger", "hotdog", "sandwich", "burrito", "taco",
                    "french loaf", "corn dog", "pot pie"],
        "сладкое": ["donut", "ice cream", "popsicle", "cake", "custard", "trifle", "chocolate sauce",
                    "gingerbread", "pancake", "waffle", "eclair", "jelly bean", "jelly roll",
                    "marmalade", "lollipop", "dough"],
        "мороженое": ["ice cream", "popsicle", "ice lolly", "sherbet"],
        "напиток": ["espresso", "cappuccino", "red wine", "wine bottle", "beer glass", "beer bottle",
                    "cocktail", "pop bottle", "water bottle", "teacup", "coffee mug"],
        "гриб": ["mushroom", "agaric", "bolete", "stinkhorn", "earthstar", "hen-of-the-woods",
                 "coral fungus", "gyromitra"],
        "ягоды": ["strawberry", "raspberry"],
        "хлеб": ["french loaf", "bagel", "pretzel", "dough", "bakery"],
        "тарелка": ["plate", "soup bowl", "cup"],
        "красный": ["red wine", "rose", "red apple", "strawberry", "raspberry", "redshank",
                    "red-backed salamander", "red-breasted merganser", "traffic light", "pomegranate"],
        "жёлтый": ["banana", "lemon", "sunflower", "daisy", "yellow lady's slipper", "butternut squash",
                   "spaghetti squash", "corn", "school bus", "golden retriever"],
        "зелёный": ["granny smith", "green mamba", "green snake", "broccoli", "cucumber", "lettuce",
                    "leaf beetle", "green lizard", "frog", "tree frog", "cabbage", "celery",
                    "artichoke", "acorn squash"],
        "синий": ["blue jay", "blue whale", "bluetick", "jean"],
        "белый": ["white stork", "snow leopard", "polar bear", "egret", "snowplow", "snowmobile"],
        "ароматное": ["espresso", "cappuccino", "coffee mug", "rose", "daisy", "sunflower", "tulip",
                      "orchid", "hibiscus", "lotus", "water lily"],

        // Природа
        "цветок": ["daisy", "sunflower", "rose", "tulip", "orchid", "hibiscus", "water lily", "lotus",
                   "bougainvillea", "canna", "dahlia", "zinnia", "poppy", "columbine", "flame flower",
                   "foxglove", "frangipani"],
        "дерево": ["pine", "palm", "weeping willow", "christmas tree", "beech", "fig", "banyan",
                   "coral tree", "dragon tree"],
        "вода": ["lake shore", "seashore", "waterfall", "fountain", "swimming pool", "dock",
                 "breakwater", "sandbar", "dam", "geyser"],
        "море": ["seashore", "sandbar", "breakwater", "dock", "starfish", "jellyfish", "crab",
                 "lobster", "octopus", "conch", "coral reef", "sea lion", "pelican", "sea anemone",
                 "sea snake", "sea urchin"],
        "горы": ["alp", "cliff", "valley", "volcano", "promontory"],
        "камень": ["stone wall", "cliff", "valley", "alp", "promontory"],
        "мост": ["suspension bridge", "steel arch bridge", "viaduct"],
        "закат": ["orange", "sunflower", "sun hat", "sunbird", "red wine"],
        "пейзаж": ["valley", "alp", "cliff", "seashore", "lake shore", "promontory", "dam", "volcano",
                   "waterfall", "geyser", "stone wall"],
        "снег": ["snowplow", "snowmobile", "ski", "snow leopard", "polar bear", "ice lolly",
                 "white stork"],
        "трава": ["lawn mower", "haystack", "barn", "leaf beetle", "green mamba", "green snake",
                  "frog", "tree frog", "lettuce", "cucumber"],
        "сад": ["flowerpot", "vase", "daisy", "sunflower", "rose", "tulip", "orchid", "hibiscus",
                "dahlia", "zinnia", "poppy", "canna", "lawn mower"],

        // Город
        "здание": ["skyscraper", "church", "mosque", "palace", "library", "castle", "lighthouse",
                   "obelisk", "monastery", "temple", "pagoda", "fountain"],
        "храм": ["church", "mosque", "monastery", "synagogue", "pagoda", "temple"],
        "памятник": ["fountain", "obelisk", "lighthouse", "castle", "palace", "synagogue", "church",
                     "mosque", "pagoda", "monastery", "temple"],
        "магазин": ["bakery", "bookshop", "butcher shop", "candy store", "department store",
                    "drugstore", "florist", "shoe shop", "tobacco shop", "restaurant", "jewelry store",
                    "barbershop", "grocery store", "cafeteria", "delicatessen", "general store"],
        "монета": ["coin"],
        "конверт": ["envelope", "letter opener"],
        "канцелярия": ["ballpoint pen", "fountain pen", "pencil sharpener", "pencil box", "crayon",
                       "rubber eraser", "stapler", "quill", "notebook", "envelope", "letter opener",
                       "abacus", "carbon paper", "ink bottle"],
        "светофор": ["traffic light", "street sign", "parking meter"],
        "дорога": ["street sign", "traffic light", "parking meter", "taxi", "school bus", "cab",
                   "minivan", "trolleybus"],
        "колесо": ["wheel", "mountain bike", "bicycle-built-for-two", "tricycle", "unicycle",
                   "sports car", "car", "convertible", "racer"],

        // Люди
        // Классов «человек» в ImageNet нет, поэтому проверяем по одежде/аксессуарам,
        // которые модель возвращает для фотографий людей.
        "люди": ["ballplayer", "bridegroom", "bride", "scuba diver", "maillot", "swimming trunks",
                 "bathing cap", "trench coat", "jersey", "kimono", "gown", "sombrero", "mortarboard",
                 "lab coat", "jean", "suit", "cardigan", "tuxedo", "vestment", "fur coat",
                 "sweatshirt", "sweater", "bib", "abaya", "miniskirt", "poncho", "sarong", "serape",
                 "wig", "bow tie", "bolo tie", "necklace", "crash helmet", "football helmet",
                 "pith helmet", "ski mask", "cowboy boot", "sandal", "running shoe", "clog", "apron",
                 "bandana", "cloak", "pajama", "nightie"],
        "тень": ["sundial", "stone wall", "promontory", "alp"],

        // Хобби
        "музыка": ["guitar", "acoustic guitar", "electric guitar", "piano", "grand piano", "violin",
                   "cello", "harp", "saxophone", "trumpet", "flute", "drum", "accordion", "banjo",
                   "maraca", "ocarina", "trombone", "organ", "steel drum", "drumstick", "chime",
                   "electric bass", "mandolin", "whistle", "xylophone", "castanet", "clavichord",
                   "cornet", "french horn", "gong"],
        "струнные": ["guitar", "acoustic guitar", "electric guitar", "violin", "cello", "harp",
                     "banjo", "mandolin", "electric bass", "clavichord"],
        "инструменты": ["hammer", "screwdriver", "power drill", "wrench", "chainsaw", "chain saw",
                        "plow", "carpenter's kit", "carpenter's square", "mallet", "pick", "hoe",
                        "hatchet", "sledge", "ax"],
        "спортинвентарь": ["soccer ball", "basketball", "tennis ball", "racket", "ski", "snowboard",
                           "surfboard", "volleyball", "baseball", "golf ball", "ping-pong ball",
                           "cricket ball", "football", "rugby ball", "bathing cap", "swimming trunks",
                           "golf cart", "punching bag", "barbell", "horizontal bar", "parallel bars",
                           "balance beam"],
    ]

    /// Собирает список ключевых слов из нескольких базовых групп.
    private static func merged(_ keys: [String]) -> [String] {
        Array(Set(keys.flatMap { all[$0] ?? [] }))
    }

    /// Составные группы (объединение базовых).
    static let groups: [String: [String]] = [
        "питомец": merged(["кот", "собака"]),
        "техника": merged(["телефон", "компьютер", "телевизор", "пульт", "клавиатура", "мышь", "принтер", "плеер"]),
        "экран": merged(["телевизор", "телефон", "компьютер"]),
        "жёлтая книга": merged(["книга", "жёлтый"]),
        "красный фрукт": merged(["фрукт", "красный"]),
        "еда на тарелке": merged(["тарелка", "фастфуд", "пицца"]),
        "летающее": merged(["самолёт", "птица", "вертолёт"]),
        "транспорт на дороге": merged(["машина", "автобус"]),
        "селфи в зеркале": merged(["зеркало", "люди"]),
        "растение": merged(["цветок", "дерево", "комнатное растение"]),
    ]

    /// Возвращает английские названия классов для ключа. Если ключ не найден — пустой массив.
    static func keywords(for key: String) -> [String] {
        groups[key] ?? all[key] ?? []
    }

    /// Эмодзи для ключей словаря (используются в мини-играх).
    static let emoji: [String: String] = [
        "кот": "🐱", "собака": "🐶", "птица": "🐦", "лошадь": "🐴", "рыба": "🐠",
        "бабочка": "🦋", "насекомое": "🐝", "морское": "🐙", "дикое животное": "🦁",
        "часы": "🕐", "круглое": "⚽", "книга": "📚", "кружка": "☕", "посуда": "🍽️",
        "обувь": "👟", "одежда": "👕", "головной убор": "🧢", "очки": "👓",
        "сумка": "🎒", "замок": "🔒", "окно": "🪟", "лампа": "💡", "игрушка": "🧸",
        "подушка": "🛏️", "ваза": "🏺", "зеркало": "🪞", "мебель": "🛋️",
        "комнатное растение": "🪴", "телефон": "📱", "компьютер": "💻", "телевизор": "📺",
        "пульт": "🎛️", "клавиатура": "⌨️", "мышь": "🖱️", "принтер": "🖨️", "плеер": "🎧",
        "машина": "🚗", "велосипед": "🚲", "мотоцикл": "🏍️", "самолёт": "✈️",
        "корабль": "🚢", "поезд": "🚆", "вертолёт": "🚁", "автобус": "🚌",
        "фрукт": "🍎", "цитрус": "🍊", "овощ": "🥕", "пицца": "🍕", "фастфуд": "🍔",
        "сладкое": "🍩", "мороженое": "🍦", "напиток": "🥤", "гриб": "🍄", "ягоды": "🍓",
        "хлеб": "🍞", "тарелка": "🍽️", "красный": "🔴", "жёлтый": "🟡", "зелёный": "🟢",
        "синий": "🔵", "белый": "⚪", "ароматное": "🌹", "цветок": "🌸", "дерево": "🌳",
        "вода": "💧", "море": "🌊", "горы": "⛰️", "камень": "🪨", "мост": "🌉",
        "закат": "🌇", "пейзаж": "🏞️", "снег": "❄️", "трава": "🌿", "сад": "🌺",
        "здание": "🏢", "храм": "⛪", "памятник": "🗽", "магазин": "🏪", "монета": "🪙",
        "конверт": "✉️", "канцелярия": "✏️", "светофор": "🚦", "дорога": "🛣️",
        "колесо": "🛞", "люди": "🧍", "тень": "🌑", "музыка": "🎸", "струнные": "🎻",
        "инструменты": "🔧", "спортинвентарь": "🏀", "питомец": "🐾", "техника": "📟",
        "экран": "🖥️", "жёлтая книга": "📒", "красный фрукт": "🍓", "еда на тарелке": "🍛",
        "летающее": "🕊️", "транспорт на дороге": "🚗", "селфи в зеркале": "🤳",
        "растение": "🪴",
    ]

    /// Эмодзи для ключа (или «📷», если ключ неизвестен).
    static func emoji(for key: String) -> String {
        emoji[key] ?? "📷"
    }
}

// MARK: - Список из 100 заданий

/// Предустановленный список из 100 уникальных заданий (на русском).
/// Задания выдаются в случайном порядке; пропущенное уходит в конец очереди.
enum QuestLibrary {

    /// Категории заданий в порядке появления (для чипов-фильтров).
    static let categories: [String] = {
        var seen = Set<String>()
        var result: [String] = []
        for quest in quests where seen.insert(quest.category).inserted {
            result.append(quest.category)
        }
        return result
    }()

    static let quests: [QuestDefinition] = [
        // --- Животные (10) ---
        QuestDefinition(text: "Сфотографируй кота", category: "Животные", keywordKey: "кот"),
        QuestDefinition(text: "Сфотографируй собаку", category: "Животные", keywordKey: "собака"),
        QuestDefinition(text: "Сфотографируй домашнего питомца", category: "Животные", keywordKey: "питомец"),
        QuestDefinition(text: "Сфотографируй птицу", category: "Животные", keywordKey: "птица"),
        QuestDefinition(text: "Сфотографируй лошадь (можно игрушечную)", category: "Животные", keywordKey: "лошадь"),
        QuestDefinition(text: "Сфотографируй дикое животное (игрушку или картинку)", category: "Животные", keywordKey: "дикое животное"),
        QuestDefinition(text: "Сфотографируй рыбу (можно в аквариуме)", category: "Животные", keywordKey: "рыба"),
        QuestDefinition(text: "Сфотографируй бабочку", category: "Животные", keywordKey: "бабочка"),
        QuestDefinition(text: "Найди насекомое и сфотографируй его", category: "Животные", keywordKey: "насекомое"),
        QuestDefinition(text: "Сфотографируй морского обитателя", category: "Животные", keywordKey: "морское"),

        // --- Дом (20) ---
        QuestDefinition(text: "Сфотографируй часы", category: "Дом", keywordKey: "часы"),
        QuestDefinition(text: "Сфоткай что-нибудь круглое", category: "Дом", keywordKey: "круглое"),
        QuestDefinition(text: "Найди книгу с жёлтой обложкой", category: "Дом", keywordKey: "жёлтая книга"),
        QuestDefinition(text: "Сфотографируй кружку с чаем или кофе", category: "Дом", keywordKey: "кружка"),
        QuestDefinition(text: "Сфотографируй ложку, вилку или нож", category: "Дом", keywordKey: "посуда"),
        QuestDefinition(text: "Сфотографируй свою обувь", category: "Дом", keywordKey: "обувь"),
        QuestDefinition(text: "Сфотографируй предмет одежды", category: "Дом", keywordKey: "одежда"),
        QuestDefinition(text: "Сфоткай свой головной убор", category: "Дом", keywordKey: "головной убор"),
        QuestDefinition(text: "Сфотографируй очки", category: "Дом", keywordKey: "очки"),
        QuestDefinition(text: "Сфотографируй рюкзак или сумку", category: "Дом", keywordKey: "сумка"),
        QuestDefinition(text: "Сфотографируй замок с ключом", category: "Дом", keywordKey: "замок"),
        QuestDefinition(text: "Сфотографируй окно", category: "Дом", keywordKey: "окно"),
        QuestDefinition(text: "Сфотографируй лампу, фонарь или свечу", category: "Дом", keywordKey: "лампа"),
        QuestDefinition(text: "Сфотографируй плюшевую игрушку", category: "Дом", keywordKey: "игрушка"),
        QuestDefinition(text: "Сфотографируй подушку", category: "Дом", keywordKey: "подушка"),
        QuestDefinition(text: "Сфотографируй вазу (можно с цветами)", category: "Дом", keywordKey: "ваза"),
        QuestDefinition(text: "Сфотографируй зеркало", category: "Дом", keywordKey: "зеркало"),
        QuestDefinition(text: "Сфотографируй кровать или диван", category: "Дом", keywordKey: "мебель"),
        QuestDefinition(text: "Сфотографируй комнатное растение", category: "Дом", keywordKey: "комнатное растение"),
        QuestDefinition(text: "Сфотографируй книжную полку", category: "Дом", keywordKey: "книга"),

        // --- Техника (10) ---
        QuestDefinition(text: "Сфотографируй свой телефон", category: "Техника", keywordKey: "телефон"),
        QuestDefinition(text: "Сфотографируй компьютер или ноутбук", category: "Техника", keywordKey: "компьютер"),
        QuestDefinition(text: "Сфотографируй телевизор", category: "Техника", keywordKey: "телевизор"),
        QuestDefinition(text: "Сфотографируй пульт от телевизора", category: "Техника", keywordKey: "пульт"),
        QuestDefinition(text: "Сфотографируй клавиатуру", category: "Техника", keywordKey: "клавиатура"),
        QuestDefinition(text: "Сфотографируй компьютерную мышь", category: "Техника", keywordKey: "мышь"),
        QuestDefinition(text: "Сфотографируй принтер или сканер", category: "Техника", keywordKey: "принтер"),
        QuestDefinition(text: "Сфотографируй плеер или диски", category: "Техника", keywordKey: "плеер"),
        QuestDefinition(text: "Сфотографируй устройство с экраном", category: "Техника", keywordKey: "экран"),
        QuestDefinition(text: "Сфотографируй любую цифровую технику", category: "Техника", keywordKey: "техника"),

        // --- Транспорт (8) ---
        QuestDefinition(text: "Сфотографируй автомобиль", category: "Транспорт", keywordKey: "машина"),
        QuestDefinition(text: "Сфотографируй велосипед", category: "Транспорт", keywordKey: "велосипед"),
        QuestDefinition(text: "Сфотографируй мотоцикл", category: "Транспорт", keywordKey: "мотоцикл"),
        QuestDefinition(text: "Сфотографируй самолёт (в небе или модель)", category: "Транспорт", keywordKey: "самолёт"),
        QuestDefinition(text: "Сфотографируй корабль или лодку", category: "Транспорт", keywordKey: "корабль"),
        QuestDefinition(text: "Сфотографируй поезд", category: "Транспорт", keywordKey: "поезд"),
        QuestDefinition(text: "Сфотографируй вертолёт", category: "Транспорт", keywordKey: "вертолёт"),
        QuestDefinition(text: "Сфотографируй общественный транспорт", category: "Транспорт", keywordKey: "автобус"),

        // --- Еда (18) ---
        QuestDefinition(text: "Сфотографируй любимый фрукт", category: "Еда", keywordKey: "фрукт"),
        QuestDefinition(text: "Сфотографируй красный фрукт или ягоду", category: "Еда", keywordKey: "красный фрукт"),
        QuestDefinition(text: "Сфотографируй цитрус", category: "Еда", keywordKey: "цитрус"),
        QuestDefinition(text: "Сфотографируй овощ", category: "Еда", keywordKey: "овощ"),
        QuestDefinition(text: "Сфотографируй пиццу", category: "Еда", keywordKey: "пицца"),
        QuestDefinition(text: "Сфотографируй бургер или фастфуд", category: "Еда", keywordKey: "фастфуд"),
        QuestDefinition(text: "Сфотографируй сэндвич или бутерброд", category: "Еда", keywordKey: "фастфуд"),
        QuestDefinition(text: "Сфотографируй десерт или сладость", category: "Еда", keywordKey: "сладкое"),
        QuestDefinition(text: "Сфотографируй мороженое", category: "Еда", keywordKey: "мороженое"),
        QuestDefinition(text: "Сфотографируй напиток", category: "Еда", keywordKey: "напиток"),
        QuestDefinition(text: "Сфотографируй гриб", category: "Еда", keywordKey: "гриб"),
        QuestDefinition(text: "Сфотографируй ягоды", category: "Еда", keywordKey: "ягоды"),
        QuestDefinition(text: "Сфотографируй хлеб или выпечку", category: "Еда", keywordKey: "хлеб"),
        QuestDefinition(text: "Сфотографируй тарелку с едой", category: "Еда", keywordKey: "еда на тарелке"),
        QuestDefinition(text: "Сфотографируй что-нибудь жёлтое", category: "Еда", keywordKey: "жёлтый"),
        QuestDefinition(text: "Сфотографируй что-нибудь зелёное", category: "Еда", keywordKey: "зелёный"),
        QuestDefinition(text: "Сфотографируй что-нибудь красное", category: "Еда", keywordKey: "красный"),
        QuestDefinition(text: "Сфотографируй то, что ароматно пахнет", category: "Еда", keywordKey: "ароматное"),

        // --- Природа (14) ---
        QuestDefinition(text: "Сфотографируй цветок", category: "Природа", keywordKey: "цветок"),
        QuestDefinition(text: "Сфотографируй дерево", category: "Природа", keywordKey: "дерево"),
        QuestDefinition(text: "Сфотографируй водоём (озеро, реку или фонтан)", category: "Природа", keywordKey: "вода"),
        QuestDefinition(text: "Сфотографируй море или пляж", category: "Природа", keywordKey: "море"),
        QuestDefinition(text: "Сфотографируй горы (или вид на них)", category: "Природа", keywordKey: "горы"),
        QuestDefinition(text: "Сфотографируй камень или скалу", category: "Природа", keywordKey: "камень"),
        QuestDefinition(text: "Сфотографируй мост", category: "Природа", keywordKey: "мост"),
        QuestDefinition(text: "Сфотографируй закат или рассвет", category: "Природа", keywordKey: "закат"),
        QuestDefinition(text: "Сфотографируй летящий объект (самолёт или птицу)", category: "Природа", keywordKey: "летающее"),
        QuestDefinition(text: "Сфотографируй пейзаж из окна", category: "Природа", keywordKey: "пейзаж"),
        QuestDefinition(text: "Сфотографируй снег или лёд (если есть)", category: "Природа", keywordKey: "снег"),
        QuestDefinition(text: "Сфотографируй лес или парк", category: "Природа", keywordKey: "дерево"),
        QuestDefinition(text: "Сфотографируй траву или лужайку", category: "Природа", keywordKey: "трава"),
        QuestDefinition(text: "Сфотографируй сад или огород", category: "Природа", keywordKey: "сад"),

        // --- Город (10) ---
        QuestDefinition(text: "Сфотографируй высокое здание", category: "Город", keywordKey: "здание"),
        QuestDefinition(text: "Сфотографируй церковь или храм", category: "Город", keywordKey: "храм"),
        QuestDefinition(text: "Сфотографируй памятник или фонтан", category: "Город", keywordKey: "памятник"),
        QuestDefinition(text: "Сфотографируй светофор", category: "Город", keywordKey: "светофор"),
        QuestDefinition(text: "Сфотографируй дорогу", category: "Город", keywordKey: "дорога"),
        QuestDefinition(text: "Сфотографируй вывеску или магазин", category: "Город", keywordKey: "магазин"),
        QuestDefinition(text: "Сфотографируй фонарь на улице", category: "Город", keywordKey: "лампа"),
        QuestDefinition(text: "Сфотографируй колесо", category: "Город", keywordKey: "колесо"),
        QuestDefinition(text: "Сфотографируй транспорт на дороге", category: "Город", keywordKey: "транспорт на дороге"),
        QuestDefinition(text: "Сфотографируй растение у дороги", category: "Город", keywordKey: "растение"),

        // --- Люди (6) ---
        QuestDefinition(text: "Сфотографируй человека (себя или друга)", category: "Люди", keywordKey: "люди"),
        QuestDefinition(text: "Сфотографируй улыбающегося человека", category: "Люди", keywordKey: "люди"),
        QuestDefinition(text: "Сделай селфи", category: "Люди", keywordKey: "люди"),
        QuestDefinition(text: "Сделай селфи с отражением в зеркале", category: "Люди", keywordKey: "селфи в зеркале"),
        QuestDefinition(text: "Сфотографируй свою тень", category: "Люди", keywordKey: "тень"),
        QuestDefinition(text: "Сфотографируй свои ноги в обуви", category: "Люди", keywordKey: "обувь"),

        // --- Хобби (4) ---
        QuestDefinition(text: "Сфотографируй музыкальный инструмент", category: "Хобби", keywordKey: "музыка"),
        QuestDefinition(text: "Сфотографируй струнный инструмент", category: "Хобби", keywordKey: "струнные"),
        QuestDefinition(text: "Сфотографируй спортивный инвентарь", category: "Хобби", keywordKey: "спортинвентарь"),
        QuestDefinition(text: "Сфотографируй инструмент для ремонта", category: "Хобби", keywordKey: "инструменты"),
    ]

    /// Ищет описание задания по тексту. Если текст не найден (например, из старой базы) —
    /// возвращает задание без ключевых слов, и пользователь сохраняет фото принудительно.
    static func definition(for text: String?) -> QuestDefinition? {
        guard let text else { return nil }
        return quests.first { $0.text == text }
            ?? QuestDefinition(text: text, category: "Разное", keywordKey: "")
    }
}
