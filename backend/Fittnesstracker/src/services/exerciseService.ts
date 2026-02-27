import { dbRun, dbAll, dbGet } from "../database";

export async function getAllExercises() {
    return dbAll("SELECT * FROM exercises");
}

export async function getExerciseById(id: number) {
    return dbGet("SELECT * FROM exercises WHERE id = ?", [id]);
}

export async function createExercise(name: string, weight: number) {
    const result = await dbRun("INSERT INTO exercises (name, weight) VALUES (?, ?)", [name, weight]);
    return { id: result.lastID, name, weight };
}

export async function updateExercise(id: number, name?: string, weight?: number) {
    const result = await dbRun(
        "UPDATE exercises SET name = COALESCE(?, name), weight = COALESCE(?, weight) WHERE id = ?",
        [name, weight, id]
    );
    if (result.changes === 0) return null;
    return dbGet("SELECT * FROM exercises WHERE id = ?", [id]);
}

export async function deleteExercise(id: number) {
    const result = await dbRun("DELETE FROM exercises WHERE id = ?", [id]);
    return result.changes > 0;
}
