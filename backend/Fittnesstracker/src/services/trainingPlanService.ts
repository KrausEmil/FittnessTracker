import { dbRun, dbAll, dbGet } from "../database";

export async function getAllPlans() {
    const plans = await dbAll("SELECT * FROM training_plans");

    for (const p of plans) {
        (p as any).exercises = await getExercisesForPlan(p.id);
    }

    return plans;
}

export async function getPlanById(id: number) {
    const plan = await dbGet("SELECT * FROM training_plans WHERE id = ?", [id]);
    if (!plan) return null;

    (plan as any).exercises = await getExercisesForPlan(id);
    return plan;
}

export async function createPlan(name: string) {
    const result = await dbRun("INSERT INTO training_plans (name) VALUES (?)", [name]);
    return { id: result.lastID, name };
}

export async function updatePlan(id: number, name: string) {
    const result = await dbRun("UPDATE training_plans SET name = ? WHERE id = ?", [name, id]);
    if (result.changes === 0) return null;
    return { id, name };
}

export async function deletePlan(id: number) {
    const result = await dbRun("DELETE FROM training_plans WHERE id = ?", [id]);
    return result.changes > 0;
}

export async function addExerciseToPlan(planId: number, exerciseId: number, sets: number, repetitions: number) {
    const plan = await dbGet("SELECT id FROM training_plans WHERE id = ?", [planId]);
    if (!plan) return { error: "plan_not_found" };

    const ex = await dbGet("SELECT id FROM exercises WHERE id = ?", [exerciseId]);
    if (!ex) return { error: "exercise_not_found" };

    const result = await dbRun(
        "INSERT INTO plan_exercises (plan_id, exercise_id, sets, repetitions) VALUES (?, ?, ?, ?)",
        [planId, exerciseId, sets, repetitions]
    );
    return {
        id: result.lastID,
        plan_id: planId,
        exercise_id: exerciseId,
        sets,
        repetitions
    };
}

export async function updatePlanExercise(planId: number, peId: number, sets?: number, repetitions?: number) {
    const result = await dbRun(
        "UPDATE plan_exercises SET sets = COALESCE(?, sets), repetitions = COALESCE(?, repetitions) WHERE id = ? AND plan_id = ?",
        [sets, repetitions, peId, planId]
    );
    if (result.changes === 0) return null;
    return dbGet("SELECT * FROM plan_exercises WHERE id = ?", [peId]);
}

export async function removePlanExercise(planId: number, peId: number) {
    const result = await dbRun(
        "DELETE FROM plan_exercises WHERE id = ? AND plan_id = ?",
        [peId, planId]
    );
    return result.changes > 0;
}

async function getExercisesForPlan(planId: number) {
    return dbAll(
        `SELECT pe.id as plan_exercise_id, pe.sets, pe.repetitions,
                e.id as exercise_id, e.name, e.weight
         FROM plan_exercises pe
         JOIN exercises e ON e.id = pe.exercise_id
         WHERE pe.plan_id = ?`,
        [planId]
    );
}
