use std::collections::HashMap;

/// Describes a file transfer session.
#[derive(Debug, Clone)]
pub struct TransferDescriptor {
    pub file_name: String,
    pub size_bytes: u64,
    pub mime_type: String,
    pub method_id: String,
}

/// Represents an active transfer session.
#[derive(Debug, Clone)]
pub struct Session {
    pub id: String,
    pub descriptor: TransferDescriptor,
    pub started_at: u64,
}

/// Events emitted during a transfer session lifecycle.
#[derive(Debug, Clone, PartialEq)]
pub enum SessionEvent {
    Started { session_id: String },
    Progress { fraction: f64 },
    Completed,
    Failed { reason: String },
    Cancelled,
}

/// Manages the lifecycle of optical transfer sessions.
pub trait SessionManager {
    type Error;

    fn open(&mut self, descriptor: TransferDescriptor) -> Result<Session, Self::Error>;
    fn close(&mut self, session_id: &str) -> Result<(), Self::Error>;
    fn events(&self, session_id: &str) -> Option<Vec<SessionEvent>>;
}

/// Placeholder in-memory session store for Phase 2.
#[derive(Default)]
pub struct InMemorySessionManager {
    sessions: HashMap<String, Session>,
}

impl SessionManager for InMemorySessionManager {
    type Error = String;

    fn open(&mut self, descriptor: TransferDescriptor) -> Result<Session, Self::Error> {
        let id = format!("session_{}", self.sessions.len());
        let session = Session {
            id: id.clone(),
            descriptor,
            started_at: 0,
        };
        self.sessions.insert(id.clone(), session.clone());
        Ok(session)
    }

    fn close(&mut self, session_id: &str) -> Result<(), Self::Error> {
        self.sessions.remove(session_id);
        Ok(())
    }

    fn events(&self, _session_id: &str) -> Option<Vec<SessionEvent>> {
        None
    }
}
