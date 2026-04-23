/**
 * Build entry for a single-file IIFE placed in Static Resource
 * AgentforceConversationClientEmbed (see docs/AGENTFORCE_CONVERSATION_CLIENT_EMBED.md).
 */
import { embedAgentforceClient } from "@salesforce/agentforce-conversation-client";

window.embedAgentforceClient = embedAgentforceClient;
window.__AGENTFORCE_CONVERSATION_CLIENT_STUB__ = false;
