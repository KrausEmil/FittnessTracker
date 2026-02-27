import express from "express";
import cors from "cors";
import { initDb } from "./database";

import exercisesRouter from "./routes/exercises";
import trainingPlansRouter from "./routes/trainingPlans";
import historyRouter from "./routes/history";

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use("/api/exercises", exercisesRouter);
app.use("/api/training-plans", trainingPlansRouter);
app.use("/api/history", historyRouter);

initDb().then(() => {
    app.listen(PORT, () => {
        console.log(`Server läuft auf http://localhost:${PORT}`);
    });
}).catch((err) => {
    console.error("DB Fehler:", err);
    process.exit(1);
});
