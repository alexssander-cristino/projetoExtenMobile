from database import db
from datetime import datetime

class Paciente(db.Model):
    __tablename__ = 'pacientes'
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(120), nullable=False)
    prontuario = db.Column(db.String(50))
    peso = db.Column(db.Float)
    categoria = db.Column(db.String(50))
    data_cadastro = db.Column(db.DateTime, default=datetime.utcnow)

class Prescricao(db.Model):
    __tablename__ = 'prescricoes'
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False)
    dose_total = db.Column(db.Float)
    basal = db.Column(db.Float)
    prandial = db.Column(db.Float)
    observacoes = db.Column(db.Text)
    data_prescricao = db.Column(db.DateTime, default=datetime.utcnow)

    paciente = db.relationship('Paciente', backref=db.backref('prescricoes', lazy=True))

class Acompanhamento(db.Model):
    __tablename__ = 'acompanhamentos'
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False)
    glicemia = db.Column(db.Float)
    observacao = db.Column(db.Text)
    data_registro = db.Column(db.DateTime, default=datetime.utcnow)

    paciente = db.relationship('Paciente', backref=db.backref('acompanhamentos', lazy=True))

class Alta(db.Model):
    __tablename__ = 'altas'
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('pacientes.id'), nullable=False)
    resumo = db.Column(db.Text)
    data_alta = db.Column(db.DateTime, default=datetime.utcnow)

    paciente = db.relationship('Paciente', backref=db.backref('altas', lazy=True))
