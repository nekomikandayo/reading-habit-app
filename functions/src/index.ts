import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

// Secret Manager から API キーを定義
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

export const generatePraise = onRequest(
    {
        secrets: [GEMINI_API_KEY],
        cors: true, // Flutter Webからのアクセスを許可
        region: "asia-northeast1",
        timeoutSeconds: 60,
    },
    async (req, res) => {
        try {
            const apiKey = GEMINI_API_KEY.value();

            // Flutter側からのリクエストボディの解析
            // httpsCallable経由なら req.body.data、通常のhttp.postなら req.body を参照
            const body = req.body.data || req.body;
            const { actionTitle, type } = body;
            const input = actionTitle || "読書";

            // --- 1. 書籍検索機能 (type: "search") ---
            if (type === "search") {
                try {
                    // Google Books API はキーなしでも利用できるため、Gemini用のキーには依存しない
                    const searchRes = await fetch(
                        `https://www.googleapis.com/books/v1/volumes?q=${encodeURIComponent(input)}&maxResults=20&langRestrict=ja`
                    );
                    const searchData = await searchRes.json();
                    res.status(200).send({ data: searchData });
                } catch (e) {
                    logger.error("Books API Error", e);
                    res.status(500).send({ data: { items: [], error: "Books API 呼び出しに失敗しました" } });
                }
                return;
            }

            // --- 2. AI対話機能 (Gemini) の設定 ---
            let systemPrompt = "";
            let generationConfig: any = {};

            switch (type) {
                case "task": // 【実践の種】
                    systemPrompt = `あなたは古今東西の知恵に精通した知的な司書です。読者の感想から、明日からすぐ始められる『実践の種』を3つ提案してください。
必ず以下のJSON形式でのみ返却してください。余計な解説は不要です。
{"actions":["行動1", "行動2", "行動3"]}`;
                    generationConfig = { response_mime_type: "application/json" };
                    break;

                case "praise": // 【共感と対話】
                    systemPrompt = `あなたは慈愛に満ちた司書です。読者が本を読み終えたことを心から祝福し、感想に深く共感してください。150文字程度で、温かい言葉を贈ってください。`;
                    break;

                case "prophecy": // 【予言】
                    systemPrompt = `あなたは神秘的な司書です。読者の行動が将来どのような変化をもたらすか、比喩や詩的な表現を用いて1文で予言してください。`;
                    break;

                default:
                    systemPrompt = "あなたは温厚な司書です。読者を優しく励ましてください。";
            }

            // Gemini API 呼び出し (モデルは 3 Flash Preview を指定)
            const geminiResponse = await fetch(
                `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=${apiKey}`,
                {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        contents: [{ parts: [{ text: `${systemPrompt}\n\n入力内容: ${input}` }] }],
                        generationConfig: generationConfig,
                    }),
                }
            );

            if (!geminiResponse.ok) {
                const errorData = await geminiResponse.text();
                logger.error("Gemini API Error", errorData);
                res.status(geminiResponse.status).send({ data: { error: "Gemini連携に失敗しました" } });
                return;
            }

            const result = await geminiResponse.json();
            
            // --- 重要：Geminiのレスポンスから「テキスト部分」だけを抽出 ---
            const aiText = result.candidates?.[0]?.content?.parts?.[0]?.text || "";

            // Flutter側には { data: { response: "本文" } } の形で返す
            // これにより Flutter側で jsonDecode(res.body)['data']['response'] で直感的に取れるようになります
            res.status(200).send({ 
                data: { 
                    response: aiText,
                    type: type 
                } 
            });

        } catch (error) {
            logger.error("Function Error", error);
            res.status(500).send({ data: { error: "サーバー内部エラーが発生しました" } });
        }
    }
);