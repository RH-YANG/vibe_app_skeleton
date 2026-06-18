import axios from 'axios';
import { HealthStatus } from '../types/apiTypes';

export const getHealth = () =>
    axios.get<HealthStatus>('/health');
