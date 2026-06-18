import useHealthCheck from '../../hook/health/useHealthCheck';
import s from './Home.module.css';

const Home = () => {
    // --- hook
    const { data, isLoading, error, retry } = useHealthCheck();

    // --- 연결 상태 판별
    const isConnected = !isLoading && !error && data !== null;
    const statusClass = isLoading ? 'loading' : isConnected ? 'connected' : 'error';
    const statusText = isLoading
        ? '연결 확인 중...'
        : isConnected
        ? '백엔드 연결됨'
        : '백엔드 연결 실패';

    return (
        <div className={s.container}>
            <p className={s.subtitle}>to-my-x</p>
            <h1 className={s.title}>그 사람과 다시 대화하세요</h1>

            <div className={s['status-card']}>
                <span className={s['status-label']}>Backend / Health</span>

                <div className={s['status-row']}>
                    <span className={`${s['status-dot']} ${s[statusClass]}`} />
                    <span className={`${s['status-text']} ${s[statusClass]}`}>{statusText}</span>
                </div>

                {isConnected && data && (
                    <pre className={s['response-body']}>
                        {JSON.stringify(data, null, 2)}
                    </pre>
                )}

                {error && (
                    <>
                        <span className={s['status-detail']}>{error.message}</span>
                        <button className={s['btn-retry']} onClick={retry}>
                            재시도
                        </button>
                    </>
                )}
            </div>
        </div>
    );
};

export default Home;
