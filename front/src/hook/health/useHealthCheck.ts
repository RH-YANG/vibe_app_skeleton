import { useState, useEffect } from 'react';
import { getHealth } from '../../api/healthApi';
import { HealthStatus } from '../../types/apiTypes';

const useHealthCheck = () => {
    const [data, setData] = useState<HealthStatus | null>(null);
    const [isLoading, setIsLoading] = useState<boolean>(true);
    const [error, setError] = useState<{ message: string; status: number } | null>(null);

    const check = async () => {
        setIsLoading(true);
        setError(null);
        try {
            const res = await getHealth();
            setData(res.data);
        } catch (e: unknown) {
            const err = e as { message?: string; response?: { status?: number } };
            setError({
                message: err?.message ?? '백엔드 서버에 연결할 수 없습니다.',
                status: err?.response?.status ?? 0,
            });
            setData(null);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        check();
    }, []);

    return { data, isLoading, error, retry: check };
};

export default useHealthCheck;
