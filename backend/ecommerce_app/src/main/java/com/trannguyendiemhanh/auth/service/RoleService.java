package com.trannguyendiemhanh.auth.service;

import java.util.List;
import java.util.UUID;

import com.trannguyendiemhanh.auth.entity.Role;

public interface RoleService {
    Role createRole(Role role);
    Role getRoleById(UUID id);
    Role getRoleByName(String roleName);
    List<Role> getAllRoles();
    void deleteRole(UUID id);
}
