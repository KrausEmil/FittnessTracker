import { Router, Request, Response } from "express";
import * as exerciseService from "../services/exerciseService";

const router = Router();

router.get("/", async (_req: Request, res: Response) => {
    const exercises = await exerciseService.getAllExercises();
    res.json(exercises);
});

router.get("/:id", async (req: Request, res: Response): Promise<void> => {
    const exercise = await exerciseService.getExerciseById(+req.params.id);
    if (!exercise) {
        res.status(404).json({ error: "Übung nicht gefunden" });
        return;
    }
    res.json(exercise);
});

router.post("/", async (req: Request, res: Response): Promise<void> => {
    const { name, weight } = req.body;
    if (!name) {
        res.status(400).json({ error: "Name fehlt" });
        return;
    }

    const created = await exerciseService.createExercise(name, weight ?? 0);
    res.status(201).json(created);
});

router.put("/:id", async (req: Request, res: Response): Promise<void> => {
    const { name, weight } = req.body;
    const updated = await exerciseService.updateExercise(+req.params.id, name, weight);

    if (!updated) {
        res.status(404).json({ error: "Übung nicht gefunden" });
        return;
    }

    res.json(updated);
});

router.delete("/:id", async (req: Request, res: Response): Promise<void> => {
    const deleted = await exerciseService.deleteExercise(Number(req.params.id));
    if (!deleted) {
        res.status(404).json({ error: "Übung nicht gefunden" });
        return;
    }
    res.json({ deleted: true });
});

export default router;
