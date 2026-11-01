// Prints test/refdata.jsonl: diffs computed by the original crate on
// generated inputs, one JSON object per line.
//
// Ops are written with their `Debug` form, changes as
// `[tag, old_index, new_index, value]` arrays, ratios with the `Debug` form
// of the `f32`.

use similar::algorithms::{diff_slices, Algorithm, Capture, Replace};
use similar::utils::{diff_chars, diff_graphemes, diff_lines, diff_unicode_words, diff_words};
use similar::{
    capture_diff_slices, get_close_matches, group_diff_ops, ChangeTag, DiffOp, DiffableStr,
    TextDiff,
};

struct Rng(u32);

impl Rng {
    // xorshift32
    fn next(&mut self) -> u32 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        self.0 = x;
        x & 0x7FFF_FFFF
    }

    fn below(&mut self, n: u32) -> u32 {
        self.next() % n
    }
}

fn json_str(s: &str) -> String {
    let mut out = String::from("\"");
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 || c as u32 == 0x7F || c as u32 == 0x2028 || c as u32 == 0x2029 => {
                out.push_str(&format!("\\u{:04x}", c as u32))
            }
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

fn json_strs(v: &[&str]) -> String {
    format!(
        "[{}]",
        v.iter().map(|s| json_str(s)).collect::<Vec<_>>().join(",")
    )
}

fn json_ints(v: &[u32]) -> String {
    format!(
        "[{}]",
        v.iter().map(|s| s.to_string()).collect::<Vec<_>>().join(",")
    )
}

fn alg_name(alg: Algorithm) -> &'static str {
    match alg {
        Algorithm::Myers => "Myers",
        Algorithm::Patience => "Patience",
        Algorithm::Lcs => "Lcs",
    }
}

fn tag_name(tag: ChangeTag) -> &'static str {
    match tag {
        ChangeTag::Equal => "Equal",
        ChangeTag::Delete => "Delete",
        ChangeTag::Insert => "Insert",
    }
}

fn ops_str(ops: &[DiffOp]) -> String {
    json_str(&format!("{:?}", ops))
}

fn opt(v: Option<usize>) -> String {
    match v {
        Some(v) => v.to_string(),
        None => "null".into(),
    }
}

fn changes_json<'a>(diff: &TextDiff<'a, 'a, '_, str>) -> String {
    let items: Vec<String> = diff
        .iter_all_changes()
        .map(|c| {
            format!(
                "[\"{}\",{},{},{}]",
                tag_name(c.tag()),
                opt(c.old_index()),
                opt(c.new_index()),
                json_str(c.value())
            )
        })
        .collect();
    format!("[{}]", items.join(","))
}

fn tagged_json(v: &[(ChangeTag, &str)]) -> String {
    let items: Vec<String> = v
        .iter()
        .map(|(t, s)| format!("[\"{}\",{}]", tag_name(*t), json_str(s)))
        .collect();
    format!("[{}]", items.join(","))
}

const ALGS: [Algorithm; 3] = [Algorithm::Myers, Algorithm::Patience, Algorithm::Lcs];

fn random_ints(rng: &mut Rng) -> (Vec<u32>, Vec<u32>) {
    let alphabet = 1 + rng.below(8);
    let n = rng.below(40) as usize;
    let old: Vec<u32> = (0..n).map(|_| rng.below(alphabet)).collect();
    // The new sequence is usually an edit of the old one.
    let mut new = old.clone();
    if rng.below(5) == 0 {
        let m = rng.below(40) as usize;
        new = (0..m).map(|_| rng.below(alphabet)).collect();
    } else {
        let edits = rng.below(6);
        for _ in 0..edits {
            let k = rng.below(3);
            if k == 0 && !new.is_empty() {
                let at = rng.below(new.len() as u32) as usize;
                new.remove(at);
            } else if k == 1 {
                let at = rng.below(new.len() as u32 + 1) as usize;
                new.insert(at, rng.below(alphabet + 2));
            } else if !new.is_empty() {
                let at = rng.below(new.len() as u32) as usize;
                new[at] = rng.below(alphabet + 2);
            }
        }
    }
    (old, new)
}

const LINES: &[&str] = &[
    "fn main() {\n",
    "}\n",
    "    let x = 1;\n",
    "    let y = 2;\n",
    "\n",
    "// comment\n",
    "return x;\r\n",
    "café\n",
    "日本語のテキスト\n",
    "emoji 🦀 here\n",
    "tab\tseparated\n",
    "a\r",
    "    println!(\"{}\", x);\n",
    "end",
    "x",
    "same\n",
];

fn random_text_lines(rng: &mut Rng, max: u32) -> String {
    let n = rng.below(max);
    let mut s = String::new();
    for _ in 0..n {
        s.push_str(LINES[rng.below(LINES.len() as u32) as usize]);
    }
    s
}

fn edit_text(rng: &mut Rng, text: &str) -> String {
    let mut lines: Vec<String> = text.split_inclusive('\n').map(|s| s.to_string()).collect();
    let edits = rng.below(5);
    for _ in 0..edits {
        let k = rng.below(3);
        if k == 0 && !lines.is_empty() {
            let at = rng.below(lines.len() as u32) as usize;
            lines.remove(at);
        } else if k == 1 {
            let at = rng.below(lines.len() as u32 + 1) as usize;
            lines.insert(at, LINES[rng.below(LINES.len() as u32) as usize].to_string());
        } else if !lines.is_empty() {
            let at = rng.below(lines.len() as u32) as usize;
            lines[at] = LINES[rng.below(LINES.len() as u32) as usize].to_string();
        }
    }
    lines.concat()
}

const WORD_CHARS: &[&str] = &[
    "a", "b", "c", "foo", "bar", " ", "  ", "\t", "\n", "\r\n", ".", ",", "(", ")", "'", "\"",
    "é", "e\u{301}", "🇦🇹", "🇦🇱", "👨‍👩‍👧", "❄️", "日本", "語", "32.3", "9.84", "can't", "x_y",
    "\u{3000}", "\u{a0}", "🦀", "ß",
];

fn random_words(rng: &mut Rng) -> String {
    let n = rng.below(16);
    let mut s = String::new();
    for _ in 0..n {
        s.push_str(WORD_CHARS[rng.below(WORD_CHARS.len() as u32) as usize]);
    }
    s
}

fn edit_words(rng: &mut Rng, text: &str) -> String {
    if rng.below(4) == 0 {
        return random_words(rng);
    }
    let mut parts: Vec<String> = text.chars().map(|c| c.to_string()).collect();
    let edits = rng.below(4);
    for _ in 0..edits {
        let k = rng.below(3);
        let w = WORD_CHARS[rng.below(WORD_CHARS.len() as u32) as usize].to_string();
        if k == 0 && !parts.is_empty() {
            let at = rng.below(parts.len() as u32) as usize;
            parts.remove(at);
        } else if k == 1 {
            let at = rng.below(parts.len() as u32 + 1) as usize;
            parts.insert(at, w);
        } else if !parts.is_empty() {
            let at = rng.below(parts.len() as u32) as usize;
            parts[at] = w;
        }
    }
    parts.concat()
}

fn main() {
    std::panic::set_hook(Box::new(|_| {}));
    let mut rng = Rng(0x5eed_1234);

    // Integer sequences: raw algorithm hooks, captured (compacted) ops,
    // grouping and ratios.
    for _ in 0..300 {
        let (old, new) = random_ints(&mut rng);
        for alg in ALGS {
            let mut d = Replace::new(Capture::new());
            diff_slices(alg, &mut d, &old, &new).unwrap();
            let raw = d.into_inner().into_ops();
            let mut c = Capture::new();
            diff_slices(alg, &mut c, &old, &new).unwrap();
            let plain = c.into_ops();
            let ops = capture_diff_slices(alg, &old, &new);
            let n = rng.below(4) as usize;
            let grouped = group_diff_ops(ops.clone(), n);
            let ratio = similar::get_diff_ratio(&ops, old.len(), new.len());
            println!(
                "{{\"kind\":\"ints\",\"alg\":\"{}\",\"old\":{},\"new\":{},\"plain\":{},\"raw\":{},\"ops\":{},\"n\":{},\"grouped\":{},\"ratio\":\"{:?}\"}}",
                alg_name(alg),
                json_ints(&old),
                json_ints(&new),
                ops_str(&plain),
                ops_str(&raw),
                ops_str(&ops),
                n,
                json_str(&format!("{:?}", grouped)),
                ratio
            );
        }
    }

    // Line diffs: ops, changes, unified diffs.
    for i in 0..250 {
        let max = if i % 25 == 0 { 120 } else { 14 };
        let old = random_text_lines(&mut rng, max);
        let new = if rng.below(6) == 0 {
            random_text_lines(&mut rng, max)
        } else {
            edit_text(&mut rng, &old)
        };
        for alg in ALGS {
            let diff = TextDiff::configure().algorithm(alg).diff_lines(&old, &new);
            let radius = rng.below(4) as usize;
            let hint = rng.below(3) != 0;
            let udiff = diff
                .unified_diff()
                .context_radius(radius)
                .missing_newline_hint(hint)
                .header("a/file", "b/file")
                .to_string();
            let not_terminated = TextDiff::configure()
                .algorithm(alg)
                .newline_terminated(false)
                .diff_lines(&old, &new)
                .unified_diff()
                .context_radius(radius)
                .to_string();
            let quick = similar::udiff::unified_diff(alg, &old, &new, radius, None);
            println!(
                "{{\"kind\":\"lines\",\"alg\":\"{}\",\"old\":{},\"new\":{},\"ops\":{},\"changes\":{},\"radius\":{},\"hint\":{},\"udiff\":{},\"udiffNt\":{},\"quick\":{},\"ratio\":\"{:?}\",\"utils\":{}}}",
                alg_name(alg),
                json_str(&old),
                json_str(&new),
                ops_str(diff.ops()),
                changes_json(&diff),
                radius,
                hint,
                json_str(&udiff),
                json_str(&not_terminated),
                json_str(&quick),
                diff.ratio(),
                tagged_json(&diff_lines(alg, &old, &new))
            );
        }
    }

    // Word, char, unicode word and grapheme diffs, and the tokenizers.
    for _ in 0..250 {
        let old = random_words(&mut rng);
        let new = edit_words(&mut rng, &old);
        for alg in ALGS {
            for unit in ["words", "chars", "unicode_words", "graphemes"] {
                let config = {
                    let mut c = TextDiff::configure();
                    c.algorithm(alg);
                    c
                };
                let diff = match unit {
                    "words" => config.diff_words(old.as_str(), new.as_str()),
                    "chars" => config.diff_chars(old.as_str(), new.as_str()),
                    "unicode_words" => config.diff_unicode_words(old.as_str(), new.as_str()),
                    _ => config.diff_graphemes(old.as_str(), new.as_str()),
                };
                // The remapper panics on some inputs (Lcs on two empty
                // strings produces an empty Delete op): record the panic.
                let utils = std::panic::catch_unwind(|| match unit {
                    "words" => diff_words(alg, old.as_str(), new.as_str()),
                    "chars" => diff_chars(alg, old.as_str(), new.as_str()),
                    "unicode_words" => diff_unicode_words(alg, old.as_str(), new.as_str()),
                    _ => diff_graphemes(alg, old.as_str(), new.as_str()),
                });
                let utils = match &utils {
                    Ok(v) => tagged_json(v),
                    Err(_) => "\"panic\"".to_string(),
                };
                let udiff = diff.unified_diff().context_radius(1).to_string();
                println!(
                    "{{\"kind\":\"{}\",\"alg\":\"{}\",\"old\":{},\"new\":{},\"ops\":{},\"changes\":{},\"ratio\":\"{:?}\",\"utils\":{},\"udiff\":{}}}",
                    unit,
                    alg_name(alg),
                    json_str(&old),
                    json_str(&new),
                    ops_str(diff.ops()),
                    changes_json(&diff),
                    diff.ratio(),
                    utils,
                    json_str(&udiff)
                );
            }
        }
        println!(
            "{{\"kind\":\"tokens\",\"text\":{},\"lines\":{},\"linesAndNewlines\":{},\"words\":{},\"chars\":{},\"unicodeWords\":{},\"graphemes\":{}}}",
            json_str(&old),
            json_strs(&old.tokenize_lines()),
            json_strs(&old.tokenize_lines_and_newlines()),
            json_strs(&old.tokenize_words()),
            json_strs(&old.tokenize_chars()),
            json_strs(&old.tokenize_unicode_words()),
            json_strs(&old.tokenize_graphemes())
        );
    }

    // Close matches.
    let vocabulary = [
        "apple", "ape", "peach", "puppy", "appel", "hulo", "hulu", "hali", "hoho", "amaz", "zulo",
        "blah", "hopp", "uulo", "aulo", "café", "cafe", "caffè", "日本", "日本語", "🦀rust", "rust",
        "trust", "rusty", "", "a", "ab", "ba",
    ];
    for _ in 0..300 {
        let word = vocabulary[rng.below(vocabulary.len() as u32) as usize];
        let count = rng.below(12) as usize;
        let possibilities: Vec<&str> = (0..count)
            .map(|_| vocabulary[rng.below(vocabulary.len() as u32) as usize])
            .collect();
        let n = rng.below(6) as usize;
        let cutoff = [0.0f32, 0.3, 0.5, 0.6, 0.7, 0.8, 1.0][rng.below(7) as usize];
        let matches = get_close_matches(word, &possibilities, n, cutoff);
        println!(
            "{{\"kind\":\"close\",\"word\":{},\"possibilities\":{},\"n\":{},\"cutoff\":{:?},\"matches\":{}}}",
            json_str(word),
            json_strs(&possibilities),
            n,
            cutoff,
            json_strs(&matches)
        );
    }
}
