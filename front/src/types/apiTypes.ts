export interface ApiResponse<T> {
    data: T;
    message: string;
    status: number;
}

export interface HealthStatus {
    [key: string]: unknown;
}
