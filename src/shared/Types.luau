--!strict
export type Item = {id: string, kind: string, paid: number, condition: number, authentic: boolean, restricted: boolean, inspected: boolean, qualityTag: string, gridX: number, gridY: number, rotation: number}
export type Profile = {version: number, legacyRows: number, gridRevision: number, cash: number, day: number, inventory: {Item}, reputation: number, upgrade: number, revenue: number, costs: number, tradeProfit: number, visits: number, aidDay: number, receipts: {string}}
export type Customer = {id: string, name: string, personality: string, faction: string, kind: string?, requestTag: string?, dialogue: string?, mode: string, goods: {any}, basket: {any}, basketRevision: number, quote: any?, offer: number, budget: number, tolerance: number, patience: number, state: string, color: {number}, itemId: string?, deadline: number?}
return {}
