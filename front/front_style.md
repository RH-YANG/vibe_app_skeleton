# Frontend Development Convention

## 기술 스택

- React 18 + TypeScript
- React Router DOM v6
- Axios
- CSS Modules
- React Hook Form
- Zustand (전역 상태 관리)

---

## 폴더 구조

```
src/
├── asset/
│   ├── font/
│   └── image/
│       └── icon/
├── api/                  # 순수 API 함수 (axios 호출만)
├── component/            # 재사용 가능한 UI 컴포넌트 (프로젝트별 구성)
├── page/                 # 라우트별 페이지
│   └── {feature}/
│       └── {sub-feature}/
├── hook/                 # 커스텀 훅 (프로젝트 도메인별 서브폴더 구성)
├── store/                # Zustand 전역 상태 스토어
├── config/               # 설정 파일 (메뉴 구조 등)
└── types/                # 공통 TypeScript 타입 정의
```

### 규칙
- `api/` — 순수 axios 호출 함수만 작성. React에 의존하지 않음
- `component/` — 재사용 가능한 UI 조각. 페이지에 종속되지 않음
- `page/` — 라우트에 1:1 대응하는 페이지. Context와 훅을 소비함
- `hook/` — API 함수를 가져다 쓰는 React 훅. 프로젝트 도메인에 맞게 서브폴더 구성
- `store/` — Zustand 전역 상태 스토어. 도메인별 파일로 분리

---

## 네이밍 규칙

### 파일 및 폴더
| 대상 | 규칙 | 예시 |
|---|---|---|
| 컴포넌트 파일 | PascalCase | `Header.tsx`, `ProteinDB.tsx` |
| 페이지 파일 | PascalCase | `Login.tsx`, `AdmetRun.tsx` |
| 훅 파일 | camelCase | `useLogin.ts`, `useProteinDbAPI.ts` |
| 스토어 파일 | camelCase + Store | `authStore.ts`, `userStore.ts` |
| CSS Module 파일 | 컴포넌트명 동일 | `Header.module.css` |
| 타입 파일 | camelCase | `authTypes.ts`, `apiTypes.ts` |
| 폴더 | lowercase | `member/`, `service/` |

### 변수 및 함수
| 대상 | 규칙 | 예시 |
|---|---|---|
| 일반 변수 | camelCase | `selectedOption`, `currentPage` |
| boolean 변수 | `is` 접두어 | `isLoading`, `isExpend` |
| 이벤트 핸들러 | `handle` 접두어 | `handleSubmit`, `handleSearch` |
| 상수 | UPPER_SNAKE_CASE | `SEARCH_OPTION`, `DEFAULT_PAGE` |
| State setter | `set` + State명 | `setData`, `setLoading` |
| 토글 함수 | `toggle` 접두어 | `toggleSidebar` |

### 컴포넌트
- 파일명과 컴포넌트명은 반드시 일치
- 컴포넌트명 = 파일명 (PascalCase 1:1)

---

## 컴포넌트 작성 패턴

```tsx
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import useFeature from '../../hook/service/useFeature';
import { useAuthStore } from '../../store/authStore';
import s from './ComponentName.module.css';

// 컴포넌트 외부에 상수 정의 (리렌더 방지)
const OPTION_LIST = ['option1', 'option2'];

const ComponentName = () => {
    // --- store
    const { user, isAuthed } = useAuthStore();

    // --- state
    const [data, setData] = useState(null);
    const [isLoading, setIsLoading] = useState(false);

    // --- hook
    const { result, fetchData } = useFeature();

    // --- handler
    const handleSubmit = () => { ... };
    const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => { ... };

    // --- effect
    useEffect(() => { ... }, []);

    return (
        <div className={s.container}>
            ...
        </div>
    );
};

export default ComponentName;
```

### 규칙
- 함수형 컴포넌트만 사용
- `export default ComponentName` 은 파일 하단에 단독으로 작성
- 상수는 컴포넌트 외부에 선언
- 섹션 구분: `// --- 섹션명` 주석으로 그룹화

---

## API 함수 패턴

```ts
// api/featureApi.ts
import axios from 'axios';
import { FeatureData } from '../types/featureTypes';

export const getFeature = (params: ParamType) =>
    axios.get<FeatureData>('/api/feature', { params });

export const postFeature = (body: BodyType) =>
    axios.post<FeatureData>('/api/feature', body);
```

### 규칙
- axios 호출만 작성. 상태 관리 없음
- 반환값은 axios Response 그대로 (가공 없음)
- 파일명은 `{domain}Api.ts` 형태

---

## 커스텀 훅 패턴

```ts
// hook/feature/useFeature.ts
import { useState, useEffect } from 'react';
import { getFeature } from '../../api/featureApi';
import { FeatureData } from '../../types/featureTypes';

const useFeature = (params: ParamType) => {
    const [data, setData] = useState<FeatureData | null>(null);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<{ message: string; status: number } | null>(null);

    useEffect(() => {
        const fetch = async () => {
            try {
                const res = await getFeature(params);
                setData(res.data);
            } catch (e: any) {
                setError({
                    message: e?.message ?? '오류가 발생했습니다.',
                    status: e?.response?.status ?? 500,
                });
            } finally {
                setLoading(false);
            }
        };
        fetch();
    }, []);

    return { data, loading, error };
};

export default useFeature;
```

### 규칙
- API 함수를 import해서 사용. axios 직접 호출 금지
- 반환값은 항상 `{ data, loading, error, ...handlers }` 구조
- 에러는 객체 직접 변이 없이 `{ message, status }` 형태로 setState
- 파일명은 `use` 접두어 + camelCase

---

## 타입 정의 (TypeScript)

```ts
// types/featureTypes.ts

export interface FeatureData {
    id: number;
    name: string;
    value: string;
}

export interface ApiResponse<T> {
    data: T;
    message: string;
    status: number;
}
```

### 규칙
- 공통 타입은 `src/types/` 에 도메인별로 분리
- API 응답 타입은 반드시 정의
- `interface` 우선 사용, 유니온/교차 타입이 필요한 경우 `type` 사용
- Props 타입은 컴포넌트 파일 상단에 인라인 정의

```tsx
interface Props {
    title: string;
    disabled?: boolean;
    onConfirm: () => void;
}

const Modal = ({ title, disabled = false, onConfirm }: Props) => { ... };
```

---

## CSS Modules & 스타일링

### CSS Module import
```tsx
import s from './ComponentName.module.css';

// 사용
<div className={s.container}>
<button className={`${s.btn} ${isActive ? s.active : ''}`}>
```

- CSS Module은 항상 `s` 로 import
- 조건부 클래스는 템플릿 리터럴 사용 (classnames 라이브러리 지양)

### CSS 파일 네이밍
```css
/* 클래스명: lowercase + hyphen */
.container { }
.btn-primary { }
.input-wrapper { }
```

- CSS 파일명은 컴포넌트명과 반드시 일치 (`App.tsx` → `App.css`, `Header.tsx` → `Header.module.css`)
- 전역 스타일(`:root`, `body`, `*` 리셋)은 `App.css` (일반 CSS)에 작성하고 `App.tsx`에서 import
- 컴포넌트 전용 스타일은 `{ComponentName}.module.css` (CSS Module) 사용

### 루트 폰트
```css
:root { font-size: 62.5%; } /* 1rem = 10px */
```

---

## 레이아웃 패턴

```tsx
// component/layout/LayoutWithSidebar.tsx
import { Outlet } from 'react-router-dom';
import Header from '../header/Header';
import Sidebar from '../sidebar/Sidebar';
import Footer from '../footer/Footer';
import s from './LayoutWithSidebar.module.css';

const LayoutWithSidebar = () => {
    return (
        <div className={s.wrapper}>
            <Header />
            <div className={s.body}>
                <Sidebar />
                <main className={s.main}>
                    <Outlet />
                </main>
            </div>
            <Footer />
        </div>
    );
};

export default LayoutWithSidebar;
```

- 레이아웃은 `<Outlet />`으로 중첩 라우트 렌더링
- 레이아웃명은 구조를 설명하는 이름 사용

---

## 주석 규칙

- 주석 언어: 한국어
- 섹션 구분: `// --- 섹션명`
- 비직관적인 로직에만 주석 작성 (명백한 코드에는 생략)
- 컴포넌트/함수 자체를 설명하는 주석 금지 (이름으로 표현)

```tsx
// --- state
const [isOpen, setIsOpen] = useState(false);

// 외부 클릭 감지를 위해 stopPropagation 처리
const handleInnerClick = (e: React.MouseEvent) => {
    e.stopPropagation();
};
```
