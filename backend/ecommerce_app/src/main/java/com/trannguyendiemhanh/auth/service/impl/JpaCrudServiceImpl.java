package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.service.CrudService;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public abstract class JpaCrudServiceImpl<T, ID> implements CrudService<T, ID> {

    protected final JpaRepository<T, ID> repository;

    protected JpaCrudServiceImpl(JpaRepository<T, ID> repository) {
        this.repository = repository;
    }

    @Override
    public T create(T entity) {
        return repository.save(entity);
    }

    @Override
    public T getById(ID id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Entity not found with ID: " + id));
    }

    @Override
    public List<T> getAll() {
        return repository.findAll();
    }

    @Override
    public T update(ID id, T entity) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Entity not found with ID: " + id);
        }
        return repository.save(entity);
    }

    @Override
    public void delete(ID id) {
        repository.deleteById(id);
    }
}
