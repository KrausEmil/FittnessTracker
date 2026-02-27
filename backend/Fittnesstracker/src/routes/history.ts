import { Router, Request, Response } from "express";
import * as historyService from "../services/historyService";

const router = Router();

router.get("/", async (_req: Request, res: Response) => {
    const rows = await historyService.getAllHistory();
    res.json(rows);
});

router.get("/:id", async (req: Request, res: Response): Promise<void> => {
    const row = await historyService.getHistoryById(+req.params.id);
    if (!row) {
        res.status(404).json({ error: "Eintrag nicht gefunden" });
        return;
    }
    res.json(row);
});

router.post("/", async (req: Request, res: Response): Promise<void> => {
    const { plan_id, completed_at } = req.body;
    if (!plan_id) {
        res.status(400).json({ error: "plan_id fehlt" });
        return;
    }

    const created = await historyService.createHistoryEntry(plan_id, completed_at);
    if (!created) {
        res.status(404).json({ error: "Plan nicht gefunden" });
        return;
    }

    res.status(201).json(created);
});

router.delete("/:id", async (req: Request, res: Response): Promise<void> => {
    const deleted = await historyService.deleteHistoryEntry(+req.params.id);
    if (!deleted) {
        res.status(404).json({ error: "Eintrag nicht gefunden" });
        return;
    }
    res.json({ deleted: true });
});

export default router;
