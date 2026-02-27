import { dbRun, dbAll, dbGet } from "../database";

export async function getAllHistory() {
    return dbAll(
        `SELECT wh.id, wh.plan_id, tp.name as plan_name, wh.completed_at
         FROM workout_history wh
         JOIN training_plans tp ON tp.id = wh.plan_id
         ORDER BY wh.completed_at DESC`
    );
}

export async function getHistoryById(id: number) {
    return dbGet(
        `SELECT wh.id, wh.plan_id, tp.name as plan_name, wh.completed_at
         FROM workout_history wh
         JOIN training_plans tp ON tp.id = wh.plan_id
         WHERE wh.id = ?`,
        [id]
    );
}

export async function createHistoryEntry(planId: number, completedAt?: string) {
    const plan = await dbGet("SELECT id FROM training_plans WHERE id = ?", [planId]);
    if (!plan) return null;

    let result;
    if (completedAt) {
        result = await dbRun(
            "INSERT INTO workout_history (plan_id, completed_at) VALUES (?, ?)",
            [planId, completedAt]
        );
    } else {
        result = await dbRun("INSERT INTO workout_history (plan_id) VALUES (?)", [planId]);
    }

    return dbGet("SELECT * FROM workout_history WHERE id = ?", [result.lastID]);
}

export async function deleteHistoryEntry(id: number) {
    const result = await dbRun("DELETE FROM workout_history WHERE id = ?", [id]);
    return result.changes > 0;
}
