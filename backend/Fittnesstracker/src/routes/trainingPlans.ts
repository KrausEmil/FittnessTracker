import { Router, Request, Response } from "express";
import * as planService from "../services/trainingPlanService";

const router = Router();

router.get("/", async (_req: Request, res: Response) => {
    const plans = await planService.getAllPlans();
    res.json(plans);
});

router.get("/:id", async (req: Request, res: Response): Promise<void> => {
    const plan = await planService.getPlanById(+req.params.id);
    if (!plan) {
        res.status(404).json({ error: "Plan nicht gefunden" });
        return;
    }
    res.json(plan);
});

router.post("/", async (req: Request, res: Response): Promise<void> => {
    const { name } = req.body;
    if (!name) {
        res.status(400).json({ error: "Name fehlt" });
        return;
    }
    const created = await planService.createPlan(name);
    res.status(201).json(created);
});

router.put("/:id", async (req: Request, res: Response): Promise<void> => {
    const { name } = req.body;
    if (!name) {
        res.status(400).json({ error: "Name fehlt" });
        return;
    }
    const updated = await planService.updatePlan(+req.params.id, name);
    if (!updated) {
        res.status(404).json({ error: "Plan nicht gefunden" });
        return;
    }
    res.json(updated);
});

router.delete("/:id", async (req: Request, res: Response): Promise<void> => {
    const deleted = await planService.deletePlan(+req.params.id);
    if (!deleted) {
        res.status(404).json({ error: "Plan nicht gefunden" });
        return;
    }
    res.json({ deleted: true });
});

router.post("/:id/exercises", async (req: Request, res: Response): Promise<void> => {
    const { exercise_id, sets, repetitions } = req.body;
    if (!exercise_id) {
        res.status(400).json({ error: "exercise_id fehlt" });
        return;
    }

    const result = await planService.addExerciseToPlan(
        Number(req.params.id), exercise_id, sets ?? 3, repetitions ?? 10
    );

    if ("error" in result) {
        const msg = result.error === "plan_not_found" ? "Plan nicht gefunden" : "Übung nicht gefunden";
        res.status(404).json({ error: msg });
        return;
    }

    res.status(201).json(result);
});

router.put("/:id/exercises/:peId", async (req: Request, res: Response): Promise<void> => {
    const { sets, repetitions } = req.body;
    const updated = await planService.updatePlanExercise(
        +req.params.id, +req.params.peId, sets, repetitions
    );
    if (!updated) {
        res.status(404).json({ error: "Eintrag nicht gefunden" });
        return;
    }
    res.json(updated);
});

router.delete("/:id/exercises/:peId", async (req: Request, res: Response): Promise<void> => {
    const deleted = await planService.removePlanExercise(
        +req.params.id, +req.params.peId
    );
    if (!deleted) {
        res.status(404).json({ error: "Eintrag nicht gefunden" });
        return;
    }
    res.json({ deleted: true });
});

export default router;
