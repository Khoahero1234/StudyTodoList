const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getProjects = async (req, res) => {
    try {
        const projects = await prisma.project.findMany({
            where: { userId: req.user.id, deletedAt: null },
            orderBy: { createdAt: 'desc' },
            include: {
                _count: {
                    select: { tasks: true }
                }
            }
        });

        res.json({ success: true, data: projects });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getProjectById = async (req, res) => {
    try {
        const project = await prisma.project.findFirst({
            where: { id: req.params.id, userId: req.user.id, deletedAt: null },
            include: {
                tasks: {
                    where: { deletedAt: null },
                    include: { subTasks: true }
                }
            }
        });

        if (!project) return res.status(404).json({ success: false, message: 'Project not found' });

        res.json({ success: true, data: project });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.createProject = async (req, res) => {
    try {
        const { name, description, color } = req.body;

        if (!name) return res.status(400).json({ success: false, message: 'Project name is required' });

        const project = await prisma.project.create({
            data: {
                userId: req.user.id,
                name,
                description,
                color: color || '#6C63FF'
            }
        });

        res.status(201).json({ success: true, data: project });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.updateProject = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description, color, isArchived } = req.body;

        const existing = await prisma.project.findFirst({
            where: { id, userId: req.user.id, deletedAt: null }
        });

        if (!existing) return res.status(404).json({ success: false, message: 'Project not found' });

        const dataToUpdate = {};
        if (name !== undefined) dataToUpdate.name = name;
        if (description !== undefined) dataToUpdate.description = description;
        if (color !== undefined) dataToUpdate.color = color;
        if (isArchived !== undefined) dataToUpdate.isArchived = Boolean(isArchived);

        const project = await prisma.project.update({
            where: { id },
            data: dataToUpdate
        });

        res.json({ success: true, data: project });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteProject = async (req, res) => {
    try {
        const { id } = req.params;

        const existing = await prisma.project.findFirst({
            where: { id, userId: req.user.id, deletedAt: null }
        });

        if (!existing) return res.status(404).json({ success: false, message: 'Project not found' });

        await prisma.project.update({
            where: { id },
            data: { deletedAt: new Date() }
        });

        res.json({ success: true, message: 'Project deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
