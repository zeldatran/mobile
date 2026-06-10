package com.trannguyendiemhanh.auth.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.trannguyendiemhanh.auth.entity.Tag;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface TagRepository extends JpaRepository<Tag, UUID> {
    Optional<Tag> findByTagName(String tagName);
    Optional<Tag> findByTagNameIgnoreCase(String tagName);
}
